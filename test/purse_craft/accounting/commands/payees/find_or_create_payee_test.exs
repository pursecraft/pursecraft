defmodule PurseCraft.Accounting.Commands.Payees.FindOrCreatePayeeTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Accounting.Commands.Payees.FindOrCreatePayee
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
    test "with owner role (authorized scope) finds existing payee", %{workspace: workspace, user: user, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      existing_payee = AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Grocery Store")

      assert {:ok, %Payee{} = payee} = FindOrCreatePayee.call(scope, workspace, "Grocery Store")
      assert payee.id == existing_payee.id
      assert payee.name == "Grocery Store"
    end

    test "with owner role (authorized scope) creates new payee when not found", %{
      workspace: workspace,
      user: user,
      scope: scope
    } do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      assert {:ok, %Payee{} = payee} = FindOrCreatePayee.call(scope, workspace, "New Store")
      assert payee.name == "New Store"
      assert payee.workspace_id == workspace.id
    end

    test "with editor role (authorized scope) finds or creates payee", %{workspace: workspace, user: user, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)

      assert {:ok, %Payee{} = payee} = FindOrCreatePayee.call(scope, workspace, "Editor Store")
      assert payee.name == "Editor Store"
      assert payee.workspace_id == workspace.id
    end

    test "with commenter role (unauthorized scope) returns error", %{workspace: workspace, user: user, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)

      assert {:error, :unauthorized} = FindOrCreatePayee.call(scope, workspace, "Commenter Store")
    end

    test "with no association to workspace (unauthorized scope) returns error", %{workspace: workspace, scope: scope} do
      assert {:error, :unauthorized} = FindOrCreatePayee.call(scope, workspace, "Unauthorized Store")
    end

    test "trims whitespace from payee name", %{workspace: workspace, user: user, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      assert {:ok, %Payee{} = payee} = FindOrCreatePayee.call(scope, workspace, "  Trimmed Store  ")
      assert payee.name == "Trimmed Store"
    end

    test "returns error for empty payee name", %{workspace: workspace, user: user, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      assert {:error, :invalid_payee_name} = FindOrCreatePayee.call(scope, workspace, "")
    end

    test "returns error for whitespace-only payee name", %{workspace: workspace, user: user, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      assert {:error, :invalid_payee_name} = FindOrCreatePayee.call(scope, workspace, "   ")
    end

    test "returns error for non-string payee name", %{workspace: workspace, user: user, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      assert {:error, :invalid_payee_name} = FindOrCreatePayee.call(scope, workspace, nil)
      assert {:error, :invalid_payee_name} = FindOrCreatePayee.call(scope, workspace, 123)
    end

    test "finds existing payee with trimmed name match", %{workspace: workspace, user: user, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      existing_payee = AccountingFactory.insert(:payee, workspace_id: workspace.id, name: "Store Name")

      assert {:ok, %Payee{} = payee} = FindOrCreatePayee.call(scope, workspace, "  Store Name  ")
      assert payee.id == existing_payee.id
      assert payee.name == "Store Name"
    end
  end
end
