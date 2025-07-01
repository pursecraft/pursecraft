defmodule PurseCraft.Budgeting.Commands.Envelopes.DeleteEnvelopeTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Envelopes.DeleteEnvelope
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastWorkspace

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

  describe "call/3" do
    test "with owner role (authorized scope) deletes an envelope", %{
      user: user,
      scope: scope,
      workspace: workspace,
      envelope: envelope
    } do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      assert {:ok, deleted_envelope} = DeleteEnvelope.call(scope, workspace, envelope)
      assert deleted_envelope.id == envelope.id
      assert_raise Ecto.NoResultsError, fn -> Repo.get!(Envelope, envelope.id) end
    end

    test "with editor role (authorized scope) deletes an envelope", %{workspace: workspace, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, deleted_envelope} = DeleteEnvelope.call(scope, workspace, envelope)
      assert deleted_envelope.id == envelope.id
      assert_raise Ecto.NoResultsError, fn -> Repo.get!(Envelope, envelope.id) end
    end

    test "with commenter role (unauthorized scope) returns error", %{workspace: workspace, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = DeleteEnvelope.call(scope, workspace, envelope)
      assert Repo.get(Envelope, envelope.id)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{
      workspace: workspace,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = DeleteEnvelope.call(scope, workspace, envelope)
      assert Repo.get(Envelope, envelope.id)
    end

    test "broadcasts envelope_deleted event when envelope is deleted successfully", %{
      user: user,
      scope: scope,
      workspace: workspace,
      envelope: envelope
    } do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      expect(BroadcastWorkspace, :call, fn broadcast_workspace, {:envelope_deleted, broadcast_envelope} ->
        assert broadcast_workspace.id == workspace.id
        assert broadcast_envelope.id == envelope.id
        :ok
      end)

      assert {:ok, deleted_envelope} = DeleteEnvelope.call(scope, workspace, envelope)
      assert deleted_envelope.id == envelope.id

      verify!()
    end
  end
end
