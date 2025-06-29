defmodule PurseCraft.Budgeting.Commands.Envelopes.UpdateEnvelopeTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Envelopes.UpdateEnvelope
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

  describe "call/4" do
    test "with string keys in attrs updates an envelope correctly", %{workspace: workspace, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      updated_envelope = %{envelope | name: "String Key Updated Envelope"}

      stub(EnvelopeRepository, :update, fn ^envelope, attrs ->
        assert attrs.name == "String Key Updated Envelope"
        {:ok, updated_envelope}
      end)

      attrs = %{"name" => "String Key Updated Envelope"}

      assert {:ok, ^updated_envelope} = UpdateEnvelope.call(scope, workspace, envelope, attrs)
    end

    test "with invalid data returns error changeset", %{workspace: workspace, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      changeset = %Ecto.Changeset{valid?: false}

      stub(EnvelopeRepository, :update, fn ^envelope, _attrs ->
        {:error, changeset}
      end)

      attrs = %{name: ""}

      assert {:error, ^changeset} = UpdateEnvelope.call(scope, workspace, envelope, attrs)
    end

    test "with owner role (authorized scope) updates an envelope", %{workspace: workspace, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      updated_envelope = %{envelope | name: "Owner Updated Envelope"}

      stub(EnvelopeRepository, :update, fn ^envelope, attrs ->
        assert attrs.name == "Owner Updated Envelope"
        {:ok, updated_envelope}
      end)

      attrs = %{name: "Owner Updated Envelope"}

      assert {:ok, ^updated_envelope} = UpdateEnvelope.call(scope, workspace, envelope, attrs)
    end

    test "with editor role (authorized scope) updates an envelope", %{workspace: workspace, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      updated_envelope = %{envelope | name: "Editor Updated Envelope"}

      stub(EnvelopeRepository, :update, fn ^envelope, attrs ->
        assert attrs.name == "Editor Updated Envelope"
        {:ok, updated_envelope}
      end)

      attrs = %{name: "Editor Updated Envelope"}

      assert {:ok, ^updated_envelope} = UpdateEnvelope.call(scope, workspace, envelope, attrs)
    end

    test "with commenter role (unauthorized scope) returns error", %{workspace: workspace, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Commenter Updated Envelope"}

      assert {:error, :unauthorized} = UpdateEnvelope.call(scope, workspace, envelope, attrs)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{
      workspace: workspace,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Unauthorized Updated Envelope"}

      assert {:error, :unauthorized} = UpdateEnvelope.call(scope, workspace, envelope, attrs)
    end

    test "invokes BroadcastWorkspace when envelope is updated successfully", %{workspace: workspace, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      updated_envelope = %{envelope | name: "Broadcast Test Updated Envelope"}

      stub(EnvelopeRepository, :update, fn ^envelope, _attrs -> {:ok, updated_envelope} end)

      expect(BroadcastWorkspace, :call, fn ^workspace, {:envelope_updated, ^updated_envelope} -> :ok end)

      attrs = %{name: "Broadcast Test Updated Envelope"}

      assert {:ok, ^updated_envelope} = UpdateEnvelope.call(scope, workspace, envelope, attrs)

      verify!()
    end
  end
end
