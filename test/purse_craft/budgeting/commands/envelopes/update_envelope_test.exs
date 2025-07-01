defmodule PurseCraft.Budgeting.Commands.Envelopes.UpdateEnvelopeTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Envelopes.UpdateEnvelope
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

  describe "call/4" do
    test "with owner role (authorized scope) updates envelope successfully", %{
      user: user,
      scope: scope,
      workspace: workspace,
      envelope: envelope
    } do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      attrs = %{name: "Updated Envelope Name"}

      assert {:ok, updated_envelope} = UpdateEnvelope.call(scope, workspace, envelope, attrs)
      assert updated_envelope.name == "Updated Envelope Name"
      assert updated_envelope.id == envelope.id
    end

    test "with editor role (authorized scope) updates envelope successfully", %{workspace: workspace, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)
      attrs = %{name: "Editor Updated Envelope"}

      assert {:ok, updated_envelope} = UpdateEnvelope.call(scope, workspace, envelope, attrs)
      assert updated_envelope.name == "Editor Updated Envelope"
    end

    test "with commenter role (unauthorized scope) returns error", %{workspace: workspace, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)
      attrs = %{name: "Commenter Envelope"}

      assert {:error, :unauthorized} = UpdateEnvelope.call(scope, workspace, envelope, attrs)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{
      workspace: workspace,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      attrs = %{name: "Unauthorized Envelope"}

      assert {:error, :unauthorized} = UpdateEnvelope.call(scope, workspace, envelope, attrs)
    end

    test "with invalid attributes returns changeset error", %{
      user: user,
      scope: scope,
      workspace: workspace,
      envelope: envelope
    } do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      attrs = %{name: ""}

      assert {:error, changeset} = UpdateEnvelope.call(scope, workspace, envelope, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with string keys in attrs updates envelope correctly", %{
      user: user,
      scope: scope,
      workspace: workspace,
      envelope: envelope
    } do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      attrs = %{"name" => "String Key Updated"}

      assert {:ok, updated_envelope} = UpdateEnvelope.call(scope, workspace, envelope, attrs)
      assert updated_envelope.name == "String Key Updated"
    end

    test "broadcasts envelope_updated event when envelope is updated successfully", %{
      user: user,
      scope: scope,
      workspace: workspace,
      envelope: envelope
    } do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      expect(BroadcastWorkspace, :call, fn received_workspace, {:envelope_updated, received_envelope} ->
        assert received_workspace.id == workspace.id
        assert received_envelope.name == "Broadcast Test Envelope"
        :ok
      end)

      attrs = %{name: "Broadcast Test Envelope"}

      assert {:ok, updated_envelope} = UpdateEnvelope.call(scope, workspace, envelope, attrs)
      assert updated_envelope.name == "Broadcast Test Envelope"

      verify!()
    end
  end
end
