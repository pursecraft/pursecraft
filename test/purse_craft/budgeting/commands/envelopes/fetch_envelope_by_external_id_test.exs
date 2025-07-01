defmodule PurseCraft.Budgeting.Commands.Envelopes.FetchEnvelopeByExternalIdTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Envelopes.FetchEnvelopeByExternalId
  alias PurseCraft.Budgeting.Repositories.EnvelopeRepository
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

  setup do
    workspace = CoreFactory.insert(:workspace)
    category = BudgetingFactory.insert(:category, workspace_id: workspace.id)

    %{
      workspace: workspace,
      category: category
    }
  end

  describe "call/4" do
    test "with owner role (authorized scope) returns envelope", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      envelope = %Envelope{id: 1, name: "Test Envelope", category_id: category.id, external_id: Ecto.UUID.generate()}

      stub(EnvelopeRepository, :get_by_external_id_and_workspace_id, fn external_id, workspace_id, _opts ->
        assert external_id == envelope.external_id
        assert workspace_id == workspace.id
        envelope
      end)

      assert {:ok, ^envelope} = FetchEnvelopeByExternalId.call(scope, workspace, envelope.external_id)
    end

    test "with preload option returns envelope with preloaded associations", %{
      workspace: workspace,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      envelope = %Envelope{
        id: 1,
        name: "Test Envelope",
        category_id: category.id,
        external_id: Ecto.UUID.generate(),
        category: category
      }

      stub(EnvelopeRepository, :get_by_external_id_and_workspace_id, fn external_id, workspace_id, opts ->
        assert external_id == envelope.external_id
        assert workspace_id == workspace.id
        assert opts == [preload: [:category]]
        envelope
      end)

      assert {:ok, ^envelope} =
               FetchEnvelopeByExternalId.call(scope, workspace, envelope.external_id, preload: [:category])
    end

    test "with invalid external_id returns not found error", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      external_id = Ecto.UUID.generate()

      stub(EnvelopeRepository, :get_by_external_id_and_workspace_id, fn ^external_id, _workspace_id, _opts ->
        nil
      end)

      assert {:error, :not_found} = FetchEnvelopeByExternalId.call(scope, workspace, external_id)
    end

    test "with editor role (authorized scope) returns envelope", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      envelope = %Envelope{id: 1, name: "Editor Envelope", category_id: category.id, external_id: Ecto.UUID.generate()}

      stub(EnvelopeRepository, :get_by_external_id_and_workspace_id, fn _external_id, _workspace_id, _opts ->
        envelope
      end)

      assert {:ok, ^envelope} = FetchEnvelopeByExternalId.call(scope, workspace, envelope.external_id)
    end

    test "with commenter role (authorized scope) returns envelope", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      envelope = %Envelope{id: 1, name: "Commenter Envelope", category_id: category.id, external_id: Ecto.UUID.generate()}

      stub(EnvelopeRepository, :get_by_external_id_and_workspace_id, fn _external_id, _workspace_id, _opts ->
        envelope
      end)

      assert {:ok, ^envelope} = FetchEnvelopeByExternalId.call(scope, workspace, envelope.external_id)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      external_id = Ecto.UUID.generate()

      assert {:error, :unauthorized} = FetchEnvelopeByExternalId.call(scope, workspace, external_id)
    end

    test "with envelope from different workspace returns not found", %{category: category} do
      different_workspace = CoreFactory.insert(:workspace)
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: different_workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      envelope = %Envelope{
        id: 1,
        name: "Different Workspace Envelope",
        category_id: category.id,
        external_id: Ecto.UUID.generate()
      }

      stub(EnvelopeRepository, :get_by_external_id_and_workspace_id, fn external_id, workspace_id, _opts ->
        assert external_id == envelope.external_id
        assert workspace_id == different_workspace.id
        nil
      end)

      assert {:error, :not_found} = FetchEnvelopeByExternalId.call(scope, different_workspace, envelope.external_id)
    end
  end
end
