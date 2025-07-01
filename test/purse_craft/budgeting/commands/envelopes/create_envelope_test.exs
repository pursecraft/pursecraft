defmodule PurseCraft.Budgeting.Commands.Envelopes.CreateEnvelopeTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Envelopes.CreateEnvelope
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastWorkspace

  setup do
    workspace = CoreFactory.insert(:workspace)
    category = BudgetingFactory.insert(:category, workspace_id: workspace.id)

    %{
      workspace: workspace,
      category: category
    }
  end

  describe "call/4" do
    test "with string keys in attrs creates an envelope correctly", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{"name" => "String Key Envelope"}

      assert {:ok, %Envelope{} = envelope} = CreateEnvelope.call(scope, workspace, category, attrs)
      assert envelope.name == "String Key Envelope"
      assert envelope.category_id == category.id
      assert envelope.position == "m"
    end

    test "with invalid data returns error changeset", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: ""}

      assert {:error, changeset} = CreateEnvelope.call(scope, workspace, category, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with owner role (authorized scope) creates an envelope", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Owner Envelope"}

      assert {:ok, %Envelope{} = envelope} = CreateEnvelope.call(scope, workspace, category, attrs)
      assert envelope.name == "Owner Envelope"
      assert envelope.category_id == category.id
    end

    test "with editor role (authorized scope) creates an envelope", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Editor Envelope"}

      assert {:ok, %Envelope{} = envelope} = CreateEnvelope.call(scope, workspace, category, attrs)
      assert envelope.name == "Editor Envelope"
      assert envelope.category_id == category.id
    end

    test "with commenter role (unauthorized scope) returns error", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Commenter Envelope"}

      assert {:error, :unauthorized} = CreateEnvelope.call(scope, workspace, category, attrs)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{
      workspace: workspace,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Unauthorized Envelope"}

      assert {:error, :unauthorized} = CreateEnvelope.call(scope, workspace, category, attrs)
    end

    test "broadcasts envelope_created event when envelope is created successfully", %{
      workspace: workspace,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      expect(BroadcastWorkspace, :call, fn broadcast_workspace, {:envelope_created, broadcast_envelope} ->
        assert broadcast_workspace.id == workspace.id
        assert broadcast_envelope.name == "Broadcast Test Envelope"
        :ok
      end)

      attrs = %{name: "Broadcast Test Envelope"}

      assert {:ok, %Envelope{}} = CreateEnvelope.call(scope, workspace, category, attrs)

      verify!()
    end

    test "assigns position 'm' for first envelope in a category", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "First Envelope"}

      assert {:ok, %Envelope{} = envelope} = CreateEnvelope.call(scope, workspace, category, attrs)
      assert envelope.position == "m"
    end

    test "assigns position before existing envelopes", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      # Create first envelope
      BudgetingFactory.insert(:envelope, category_id: category.id, position: "m")

      attrs = %{name: "Second Envelope"}

      assert {:ok, %Envelope{} = envelope} = CreateEnvelope.call(scope, workspace, category, attrs)
      assert envelope.position < "m"
      assert envelope.position == "g"
    end

    test "handles multiple envelopes being added at the top", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      # Create initial envelopes
      BudgetingFactory.insert(:envelope, category_id: category.id, position: "g")
      BudgetingFactory.insert(:envelope, category_id: category.id, position: "m")
      BudgetingFactory.insert(:envelope, category_id: category.id, position: "t")

      attrs = %{name: "New Top Envelope"}

      assert {:ok, %Envelope{} = envelope} = CreateEnvelope.call(scope, workspace, category, attrs)
      assert envelope.position < "g"
      assert envelope.position == "d"
    end

    test "returns error when first envelope is already at 'a'", %{workspace: workspace, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      # Create an envelope at the boundary
      BudgetingFactory.insert(:envelope, category_id: category.id, position: "a")

      attrs = %{name: "Cannot Place At Top"}

      assert {:error, :cannot_place_at_top} = CreateEnvelope.call(scope, workspace, category, attrs)
    end
  end
end
