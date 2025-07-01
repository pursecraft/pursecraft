defmodule PurseCraft.Accounting.Commands.Accounts.FetchAccountByExternalIdTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Accounting.Commands.Accounts.FetchAccountByExternalId
  alias PurseCraft.AccountingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

  describe "call/4" do
    setup do
      user = IdentityFactory.insert(:user)
      workspace = CoreFactory.insert(:workspace)
      scope = IdentityFactory.build(:scope, user: user)

      {:ok, user: user, workspace: workspace, scope: scope}
    end

    test "returns account when user is owner", %{user: user, workspace: workspace, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      account = AccountingFactory.insert(:account, workspace: workspace)

      assert {:ok, fetched_account} = FetchAccountByExternalId.call(scope, workspace, account.external_id)
      assert fetched_account.id == account.id
      assert fetched_account.external_id == account.external_id
    end

    test "returns account when user is editor", %{user: user, workspace: workspace, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      account = AccountingFactory.insert(:account, workspace: workspace)

      assert {:ok, fetched_account} = FetchAccountByExternalId.call(scope, workspace, account.external_id)
      assert fetched_account.id == account.id
    end

    test "returns account when user is commenter", %{user: user, workspace: workspace, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      account = AccountingFactory.insert(:account, workspace: workspace)

      assert {:ok, fetched_account} = FetchAccountByExternalId.call(scope, workspace, account.external_id)
      assert fetched_account.id == account.id
    end

    test "returns error when account not found", %{user: user, workspace: workspace, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      assert {:error, :not_found} = FetchAccountByExternalId.call(scope, workspace, Ecto.UUID.generate())
    end

    test "returns error when user has no access to workspace", %{user: user, workspace: workspace, scope: scope} do
      other_workspace = CoreFactory.insert(:workspace)
      CoreFactory.insert(:workspace_user, workspace_id: other_workspace.id, user_id: user.id, role: :owner)
      account = AccountingFactory.insert(:account, workspace: workspace)

      assert {:error, :unauthorized} = FetchAccountByExternalId.call(scope, workspace, account.external_id)
    end

    test "passes options to fetch account with preload", %{user: user, workspace: workspace, scope: scope} do
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      account = AccountingFactory.insert(:account, workspace: workspace)
      opts = [preload: [:workspace]]

      assert {:ok, fetched_account} = FetchAccountByExternalId.call(scope, workspace, account.external_id, opts)
      assert fetched_account.id == account.id
      assert %Ecto.Association.NotLoaded{} != fetched_account.workspace
    end
  end
end
