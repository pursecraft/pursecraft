defmodule PurseCraft.Budgeting.Commands.Envelopes.FetchEnvelopeByExternalIdTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting.Commands.Envelopes.FetchEnvelopeByExternalId
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

  setup do
    user = IdentityFactory.insert(:user)
    workspace = CoreFactory.insert(:workspace)
    category = BudgetingFactory.insert(:category, workspace_id: workspace.id)
    envelope = BudgetingFactory.insert(:envelope, category_id: category.id)
    scope = IdentityFactory.build(:scope, user: user)

    %{
      user: user,
      workspace: workspace,
      category: category,
      envelope: envelope,
      scope: scope
    }
  end

  describe "call/4" do
    test "with owner role (authorized scope) returns envelope", %{
      user: user,
      scope: scope,
      workspace: workspace,
      envelope: envelope
    } do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      assert {:ok, fetched_envelope} = FetchEnvelopeByExternalId.call(scope, workspace, envelope.external_id)
      assert fetched_envelope.id == envelope.id
      assert fetched_envelope.external_id == envelope.external_id
    end

    test "with editor role (authorized scope) returns envelope", %{workspace: workspace, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, fetched_envelope} = FetchEnvelopeByExternalId.call(scope, workspace, envelope.external_id)
      assert fetched_envelope.id == envelope.id
    end

    test "with commenter role (authorized scope) returns envelope", %{workspace: workspace, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, fetched_envelope} = FetchEnvelopeByExternalId.call(scope, workspace, envelope.external_id)
      assert fetched_envelope.id == envelope.id
    end

    test "with no association to workspace (unauthorized scope) returns error", %{
      workspace: workspace,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = FetchEnvelopeByExternalId.call(scope, workspace, envelope.external_id)
    end

    test "with invalid external_id returns not found error", %{user: user, scope: scope, workspace: workspace} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      invalid_external_id = Ecto.UUID.generate()

      assert {:error, :not_found} = FetchEnvelopeByExternalId.call(scope, workspace, invalid_external_id)
    end

    test "with preload option returns envelope with preloaded associations", %{
      user: user,
      scope: scope,
      workspace: workspace,
      category: category,
      envelope: envelope
    } do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      assert {:ok, fetched_envelope} =
               FetchEnvelopeByExternalId.call(scope, workspace, envelope.external_id, preload: [:category])

      assert fetched_envelope.id == envelope.id
      assert Ecto.assoc_loaded?(fetched_envelope.category)
      assert fetched_envelope.category.id == category.id
    end

    test "with envelope from different workspace returns not found", %{envelope: envelope} do
      different_workspace = CoreFactory.insert(:workspace)
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: different_workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      # The envelope exists but belongs to a different workspace
      assert {:error, :not_found} = FetchEnvelopeByExternalId.call(scope, different_workspace, envelope.external_id)
    end
  end
end
