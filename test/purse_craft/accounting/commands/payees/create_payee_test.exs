defmodule PurseCraft.Accounting.Commands.Payees.CreatePayeeTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Accounting.Commands.Payees.CreatePayee
  alias PurseCraft.Accounting.Schemas.Payee
  alias PurseCraft.AccountingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

  setup do
    workspace = CoreFactory.insert(:workspace)
    user = IdentityFactory.insert(:user)
    scope = IdentityFactory.build(:scope, user: user)

    %{
      workspace: workspace,
      user: user,
      scope: scope
    }
  end

  describe "call/3" do
    test "with owner role (authorized scope) creates a payee", %{workspace: workspace, user: user, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      attrs = %{name: "Grocery Store"}

      assert {:ok, %Payee{} = payee} = CreatePayee.call(scope, workspace, attrs)
      assert payee.name == "Grocery Store"
      assert payee.workspace_id == workspace.id
      assert payee.external_id != nil
    end

    test "with editor role (authorized scope) creates a payee", %{workspace: workspace, user: user, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)

      attrs = %{name: "Restaurant"}

      assert {:ok, %Payee{} = payee} = CreatePayee.call(scope, workspace, attrs)
      assert payee.name == "Restaurant"
      assert payee.workspace_id == workspace.id
      assert payee.external_id != nil
    end

    test "with commenter role (unauthorized scope) returns error", %{workspace: workspace, user: user, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)

      attrs = %{name: "Gas Station"}

      assert {:error, :unauthorized} = CreatePayee.call(scope, workspace, attrs)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{workspace: workspace, scope: scope} do
      attrs = %{name: "Coffee Shop"}

      assert {:error, :unauthorized} = CreatePayee.call(scope, workspace, attrs)
    end

    test "with string keys in attrs creates a payee correctly", %{workspace: workspace, user: user, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      attrs = %{"name" => "String Key Payee"}

      assert {:ok, %Payee{} = payee} = CreatePayee.call(scope, workspace, attrs)
      assert payee.name == "String Key Payee"
      assert payee.workspace_id == workspace.id
    end

    test "with empty name returns error changeset", %{workspace: workspace, user: user, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      attrs = %{name: ""}

      assert {:error, changeset} = CreatePayee.call(scope, workspace, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with missing name returns error changeset", %{workspace: workspace, user: user, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      attrs = %{}

      assert {:error, changeset} = CreatePayee.call(scope, workspace, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with nil name returns error changeset", %{workspace: workspace, user: user, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      attrs = %{name: nil}

      assert {:error, changeset} = CreatePayee.call(scope, workspace, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with duplicate name in same workspace returns error changeset", %{
      workspace: workspace,
      user: user,
      scope: scope
    } do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Duplicate Payee")

      attrs = %{name: "Duplicate Payee"}

      assert {:error, changeset} = CreatePayee.call(scope, workspace, attrs)
      assert %{name_hash: ["has already been taken"]} = errors_on(changeset)
    end

    test "allows duplicate names across different workspaces", %{workspace: workspace, user: user, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      other_workspace = CoreFactory.insert(:workspace)
      AccountingFactory.insert(:payee, workspace_id: other_workspace.id, name: "Cross Workspace Payee")

      attrs = %{name: "Cross Workspace Payee"}

      assert {:ok, %Payee{} = payee} = CreatePayee.call(scope, workspace, attrs)
      assert payee.name == "Cross Workspace Payee"
      assert payee.workspace_id == workspace.id
    end

    test "call/2 defaults attrs to empty map", %{workspace: workspace, user: user, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      assert {:error, changeset} = CreatePayee.call(scope, workspace)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end
end
