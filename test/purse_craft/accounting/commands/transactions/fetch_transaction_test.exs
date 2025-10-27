defmodule PurseCraft.Accounting.Commands.Transactions.FetchTransactionTest do
  use PurseCraft.DataCase, async: true

  alias Ecto.Association.NotLoaded
  alias PurseCraft.Accounting.Commands.Transactions.FetchTransaction
  alias PurseCraft.AccountingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

  setup do
    workspace = CoreFactory.insert(:workspace)
    user = IdentityFactory.insert(:user)
    CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
    scope = IdentityFactory.build(:scope, user: user)
    account = AccountingFactory.insert(:account, workspace: workspace)
    transaction = AccountingFactory.insert(:transaction, workspace: workspace, account: account)

    {:ok, workspace: workspace, scope: scope, transaction: transaction}
  end

  describe "call/4" do
    test "fetches transaction by struct", %{
      scope: scope,
      workspace: workspace,
      transaction: transaction
    } do
      assert {:ok, fetched} = FetchTransaction.call(scope, workspace, transaction)
      assert fetched.id == transaction.id
    end

    test "fetches transaction by integer id", %{
      scope: scope,
      workspace: workspace,
      transaction: transaction
    } do
      assert {:ok, fetched} = FetchTransaction.call(scope, workspace, transaction.id)
      assert fetched.id == transaction.id
    end

    test "fetches transaction by external_id", %{
      scope: scope,
      workspace: workspace,
      transaction: transaction
    } do
      assert {:ok, fetched} = FetchTransaction.call(scope, workspace, transaction.external_id)
      assert fetched.id == transaction.id
    end

    test "returns not_found for non-existent id", %{scope: scope, workspace: workspace} do
      assert {:error, :not_found} = FetchTransaction.call(scope, workspace, 999_999)
    end

    test "returns not_found for non-existent external_id", %{
      scope: scope,
      workspace: workspace
    } do
      assert {:error, :not_found} =
               FetchTransaction.call(scope, workspace, Ecto.UUID.generate())
    end

    test "returns unauthorized for different workspace", %{scope: scope, transaction: transaction} do
      other_workspace = CoreFactory.insert(:workspace)

      assert {:error, :unauthorized} =
               FetchTransaction.call(scope, other_workspace, transaction.id)
    end

    test "preloads associations when struct passed with preload option", %{
      scope: scope,
      workspace: workspace
    } do
      account = AccountingFactory.insert(:account, workspace: workspace)
      created_transaction = AccountingFactory.insert(:transaction, workspace: workspace, account: account)
      transaction = Repo.get(PurseCraft.Accounting.Schemas.Transaction, created_transaction.id)

      assert {:ok, fetched} =
               FetchTransaction.call(scope, workspace, transaction, preload: [:account])

      assert %NotLoaded{} = transaction.account
      refute match?(%NotLoaded{}, fetched.account)
    end

    test "returns struct as-is when no preload option", %{
      scope: scope,
      workspace: workspace,
      transaction: transaction
    } do
      assert {:ok, fetched} = FetchTransaction.call(scope, workspace, transaction)
      assert fetched == transaction
    end
  end
end
