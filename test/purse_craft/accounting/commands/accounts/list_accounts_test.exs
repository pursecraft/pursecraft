defmodule PurseCraft.Accounting.Commands.Accounts.ListAccountsTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Accounting.Commands.Accounts.ListAccounts
  alias PurseCraft.AccountingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

  setup do
    user = IdentityFactory.insert(:user)
    workspace = CoreFactory.insert(:workspace)
    scope = IdentityFactory.build(:scope, user: user)

    {:ok, user: user, workspace: workspace, scope: scope}
  end

  describe "call/3" do
    test "with owner role (authorized scope) returns accounts", %{
      user: user,
      scope: scope,
      workspace: workspace
    } do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      AccountingFactory.insert(:account, workspace: workspace)

      accounts = ListAccounts.call(scope, workspace)
      assert is_list(accounts)
      assert length(accounts) == 1
    end

    test "with editor role (authorized scope) returns accounts", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)
      AccountingFactory.insert(:account, workspace: workspace)

      accounts = ListAccounts.call(scope, workspace)
      assert is_list(accounts)
      assert length(accounts) == 1
    end

    test "with commenter role (authorized scope) returns accounts", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)
      AccountingFactory.insert(:account, workspace: workspace)

      accounts = ListAccounts.call(scope, workspace)
      assert is_list(accounts)
      assert length(accounts) == 1
    end

    test "with no association to workspace (unauthorized scope) returns error", %{
      scope: scope,
      workspace: workspace
    } do
      assert {:error, :unauthorized} = ListAccounts.call(scope, workspace)
    end
  end
end
