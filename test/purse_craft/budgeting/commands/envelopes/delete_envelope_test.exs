defmodule PurseCraft.Budgeting.Commands.Envelopes.DeleteEnvelopeTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Envelopes.DeleteEnvelope
  alias PurseCraft.Budgeting.Repositories.EnvelopeRepository
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastWorkspace

  setup do
    workspace = CoreFactory.insert(:workspace)
    category = BudgetingFactory.insert(:category, workspace_id: workspace.id)
    envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

    %{
      workspace: workspace,
      category: category,
      envelope: envelope
    }
  end

  describe "call/3" do
    test "with owner role (authorized scope) deletes an envelope", %{workspace: workspace, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      stub(EnvelopeRepository, :delete, fn ^envelope ->
        {:ok, envelope}
      end)

      assert {:ok, ^envelope} = DeleteEnvelope.call(scope, workspace, envelope)
    end

    test "with editor role (authorized scope) deletes an envelope", %{workspace: workspace, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      stub(EnvelopeRepository, :delete, fn ^envelope ->
        {:ok, envelope}
      end)

      assert {:ok, ^envelope} = DeleteEnvelope.call(scope, workspace, envelope)
    end

    test "with commenter role (unauthorized scope) returns error", %{workspace: workspace, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = DeleteEnvelope.call(scope, workspace, envelope)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{
      workspace: workspace,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = DeleteEnvelope.call(scope, workspace, envelope)
    end

    test "with database error returns error changeset", %{workspace: workspace, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      changeset = %Ecto.Changeset{valid?: false}

      stub(EnvelopeRepository, :delete, fn ^envelope ->
        {:error, changeset}
      end)

      assert {:error, ^changeset} = DeleteEnvelope.call(scope, workspace, envelope)
    end

    test "invokes BroadcastWorkspace when envelope is deleted successfully", %{workspace: workspace, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      stub(EnvelopeRepository, :delete, fn ^envelope -> {:ok, envelope} end)

      expect(BroadcastWorkspace, :call, fn ^workspace, {:envelope_deleted, ^envelope} -> :ok end)

      assert {:ok, ^envelope} = DeleteEnvelope.call(scope, workspace, envelope)

      verify!()
    end
  end
end
