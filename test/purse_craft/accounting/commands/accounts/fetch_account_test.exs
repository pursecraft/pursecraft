defmodule PurseCraft.Accounting.Commands.Accounts.FetchAccountTest do
  use PurseCraft.DataCase, async: true

  alias Ecto.Association.NotLoaded
  alias PurseCraft.Accounting.Commands.Accounts.FetchAccount
  alias PurseCraft.AccountingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

  setup do
    workspace = CoreFactory.insert(:workspace)
    user = IdentityFactory.insert(:user)
    CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
    scope = IdentityFactory.build(:scope, user: user)
    account = AccountingFactory.insert(:account, workspace: workspace)

    {:ok, workspace: workspace, scope: scope, account: account}
  end

  describe "call/4" do
    test "fetches account by struct", %{scope: scope, workspace: workspace, account: account} do
      assert {:ok, fetched} = FetchAccount.call(scope, workspace, account)
      assert fetched.id == account.id
    end

    test "fetches account by integer id", %{scope: scope, workspace: workspace, account: account} do
      assert {:ok, fetched} = FetchAccount.call(scope, workspace, account.id)
      assert fetched.id == account.id
    end

    test "fetches account by external_id", %{scope: scope, workspace: workspace, account: account} do
      assert {:ok, fetched} = FetchAccount.call(scope, workspace, account.external_id)
      assert fetched.id == account.id
    end

    test "returns not_found for non-existent id", %{scope: scope, workspace: workspace} do
      assert {:error, :not_found} = FetchAccount.call(scope, workspace, 999_999)
    end

    test "returns not_found for non-existent external_id", %{scope: scope, workspace: workspace} do
      assert {:error, :not_found} = FetchAccount.call(scope, workspace, Ecto.UUID.generate())
    end

    test "returns unauthorized for different workspace", %{scope: scope, account: account} do
      other_workspace = CoreFactory.insert(:workspace)
      assert {:error, :unauthorized} = FetchAccount.call(scope, other_workspace, account.id)
    end

    test "preloads associations when struct passed with preload option", %{
      scope: scope,
      workspace: workspace
    } do
      created_account = AccountingFactory.insert(:account, workspace: workspace)
      account = Repo.get(PurseCraft.Accounting.Schemas.Account, created_account.id)

      assert {:ok, fetched} = FetchAccount.call(scope, workspace, account, preload: [:workspace])
      assert %NotLoaded{} = account.workspace
      refute match?(%NotLoaded{}, fetched.workspace)
    end

    test "returns struct as-is when no preload option", %{
      scope: scope,
      workspace: workspace,
      account: account
    } do
      assert {:ok, fetched} = FetchAccount.call(scope, workspace, account)
      assert fetched == account
    end
  end
end
