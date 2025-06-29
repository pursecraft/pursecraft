defmodule PurseCraft.Accounting.Commands.Accounts.DeleteAccountTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Accounting.Commands.Accounts.DeleteAccount
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
    test "with owner role (authorized scope) deletes account successfully", %{
      user: user,
      scope: scope,
      workspace: workspace
    } do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      account = AccountingFactory.insert(:account, workspace: workspace)

      assert {:ok, deleted_account} = DeleteAccount.call(scope, workspace, account.external_id)
      assert deleted_account.id == account.id
    end

    test "with editor role (authorized scope) deletes account successfully", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)
      account = AccountingFactory.insert(:account, workspace: workspace)

      assert {:ok, deleted_account} = DeleteAccount.call(scope, workspace, account.external_id)
      assert deleted_account.id == account.id
    end

    test "with commenter role (unauthorized scope) returns error", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)
      account = AccountingFactory.insert(:account, workspace: workspace)

      assert {:error, :unauthorized} = DeleteAccount.call(scope, workspace, account.external_id)
    end

    test "with invalid external_id returns not found error", %{user: user, scope: scope, workspace: workspace} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      assert {:error, :not_found} = DeleteAccount.call(scope, workspace, Ecto.UUID.generate())
    end
  end
end
