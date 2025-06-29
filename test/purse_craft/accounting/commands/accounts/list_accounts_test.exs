defmodule PurseCraft.Accounting.Commands.Accounts.ListAccountsTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Accounting.Commands.Accounts.ListAccounts
  alias PurseCraft.AccountingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

  setup do
    user = IdentityFactory.insert(:user)
    workspace = CoreFactory.insert(:workspace)
    CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
    scope = IdentityFactory.build(:scope, user: user)

    {:ok, user: user, workspace: workspace, scope: scope}
  end

  describe "call/3" do
    test "with owner role (authorized scope) returns all workspace accounts", %{
      scope: scope,
      workspace: workspace
    } do
      account1 = AccountingFactory.insert(:account, workspace: workspace, position: "aaaa")
      account2 = AccountingFactory.insert(:account, workspace: workspace, position: "bbbb")

      accounts = ListAccounts.call(scope, workspace)
      assert length(accounts) == 2
      assert [first_account, second_account] = accounts
      assert first_account.id == account1.id
      assert second_account.id == account2.id
    end

    test "with editor role (authorized scope) returns accounts", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)
      AccountingFactory.insert(:account, workspace: workspace, position: "aaaa")

      accounts = ListAccounts.call(scope, workspace)
      assert length(accounts) == 1
    end

    test "with commenter role (authorized scope) returns accounts", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)
      AccountingFactory.insert(:account, workspace: workspace, position: "aaaa")

      accounts = ListAccounts.call(scope, workspace)
      assert length(accounts) == 1
    end

    test "returns empty list when no accounts exist", %{scope: scope, workspace: workspace} do
      accounts = ListAccounts.call(scope, workspace)
      assert accounts == []
    end

    test "returns accounts ordered by position", %{scope: scope, workspace: workspace} do
      account1 = AccountingFactory.insert(:account, workspace: workspace, position: "bbbb")
      account2 = AccountingFactory.insert(:account, workspace: workspace, position: "aaaa")

      accounts = ListAccounts.call(scope, workspace)
      assert [first_account, second_account] = accounts
      assert first_account.id == account2.id
      assert second_account.id == account1.id
    end

    test "excludes closed accounts by default", %{scope: scope, workspace: workspace} do
      AccountingFactory.insert(:account, workspace: workspace, position: "aaaa")
      AccountingFactory.insert(:account, workspace: workspace, position: "bbbb", closed_at: DateTime.utc_now())

      accounts = ListAccounts.call(scope, workspace)
      assert length(accounts) == 1
    end

    test "with no association to workspace (unauthorized scope) returns error", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = ListAccounts.call(scope, workspace)
    end

    test "returns only accounts for the specified workspace", %{scope: scope, workspace: workspace} do
      other_workspace = CoreFactory.insert(:workspace)
      AccountingFactory.insert(:account, workspace: workspace, position: "aaaa")
      AccountingFactory.insert(:account, workspace: other_workspace, position: "aaaa")

      accounts = ListAccounts.call(scope, workspace)
      assert length(accounts) == 1
    end
  end
end
