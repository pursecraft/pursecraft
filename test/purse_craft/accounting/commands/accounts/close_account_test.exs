defmodule PurseCraft.Accounting.Commands.Accounts.CloseAccountTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Accounting.Commands.Accounts.CloseAccount
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
    test "with owner role (authorized scope) closes account successfully", %{
      user: user,
      scope: scope,
      workspace: workspace
    } do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      account = AccountingFactory.insert(:account, workspace: workspace, closed_at: nil)

      assert {:ok, closed_account} = CloseAccount.call(scope, workspace, account.external_id)
      assert closed_account.id == account.id
      assert closed_account.closed_at != nil
    end

    test "with editor role (authorized scope) closes account successfully", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)
      account = AccountingFactory.insert(:account, workspace: workspace, closed_at: nil)

      assert {:ok, closed_account} = CloseAccount.call(scope, workspace, account.external_id)
      assert closed_account.id == account.id
      assert closed_account.closed_at != nil
    end

    test "with commenter role (unauthorized scope) returns error", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)
      account = AccountingFactory.insert(:account, workspace: workspace)

      assert {:error, :unauthorized} = CloseAccount.call(scope, workspace, account.external_id)
    end

    test "with no association to workspace (unauthorized scope) returns error", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      account = AccountingFactory.insert(:account, workspace: workspace)

      assert {:error, :unauthorized} = CloseAccount.call(scope, workspace, account.external_id)
    end

    test "with invalid external_id returns not found error", %{user: user, scope: scope, workspace: workspace} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      assert {:error, :not_found} = CloseAccount.call(scope, workspace, Ecto.UUID.generate())
    end
  end
end
