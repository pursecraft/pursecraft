defmodule PurseCraft.Accounting.Commands.Transactions.DeleteTransactionTest do
  use PurseCraft.DataCase, async: true

  import Ecto.Query

  alias PurseCraft.Accounting.Commands.Transactions.DeleteTransaction
  alias PurseCraft.Accounting.Schemas.Transaction
  alias PurseCraft.Accounting.Schemas.TransactionLine
  alias PurseCraft.AccountingFactory
  alias PurseCraft.BudgetingFactory
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

  describe "call/3 - authorization" do
    test "owner role deletes transaction successfully", %{
      workspace: workspace,
      scope: scope,
      account: account
    } do
      transaction = AccountingFactory.insert(:transaction, workspace: workspace, account: account)

      assert {:ok, deleted} = DeleteTransaction.call(scope, workspace, transaction.external_id)
      assert deleted.id == transaction.id
      assert Repo.get(Transaction, transaction.id) == nil
    end

    test "editor role deletes transaction successfully", %{workspace: workspace, account: account} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      transaction = AccountingFactory.insert(:transaction, workspace: workspace, account: account)

      assert {:ok, deleted} = DeleteTransaction.call(scope, workspace, transaction.external_id)
      assert deleted.id == transaction.id
    end

    test "commenter role returns unauthorized", %{workspace: workspace, account: account} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      transaction = AccountingFactory.insert(:transaction, workspace: workspace, account: account)

      assert {:error, :unauthorized} = DeleteTransaction.call(scope, workspace, transaction.external_id)
    end
  end

  describe "call/3 - happy path" do
    test "deletes transaction and cascades transaction lines", %{
      workspace: workspace,
      scope: scope,
      account: account
    } do
      category = BudgetingFactory.insert(:category, workspace: workspace)
      envelope = BudgetingFactory.insert(:envelope, category: category)

      transaction =
        AccountingFactory.insert(:transaction, workspace: workspace, account: account, amount: -1000)

      line1 =
        AccountingFactory.insert(:transaction_line,
          transaction: transaction,
          envelope: envelope,
          amount: 500
        )

      line2 =
        AccountingFactory.insert(:transaction_line,
          transaction: transaction,
          envelope: envelope,
          amount: 500
        )

      assert {:ok, _deleted} = DeleteTransaction.call(scope, workspace, transaction.external_id)

      assert Repo.get(Transaction, transaction.id) == nil
      assert Repo.get(TransactionLine, line1.id) == nil
      assert Repo.get(TransactionLine, line2.id) == nil
    end

    test "schedules payee cleanup when transaction has payee", %{
      workspace: workspace,
      scope: scope,
      account: account
    } do
      payee = AccountingFactory.insert(:payee, workspace: workspace)
      transaction = AccountingFactory.insert(:transaction, workspace: workspace, account: account, payee: payee)

      assert {:ok, _deleted} = DeleteTransaction.call(scope, workspace, transaction.external_id)

      jobs =
        Repo.all(
          from(j in Oban.Job,
            where: j.worker == "PurseCraft.Accounting.Workers.CleanupOrphanedPayeesWorker",
            where: fragment("?->>'workspace_id' = ?", j.args, ^to_string(workspace.id))
          )
        )

      assert length(jobs) == 1
    end

    test "schedules payee cleanup for line-level payees", %{
      workspace: workspace,
      scope: scope,
      account: account
    } do
      payee1 = AccountingFactory.insert(:payee, workspace: workspace)
      payee2 = AccountingFactory.insert(:payee, workspace: workspace)

      transaction =
        AccountingFactory.insert(:transaction, workspace: workspace, account: account, amount: -1000)

      AccountingFactory.insert(:transaction_line, transaction: transaction, payee: payee1, amount: 500)
      AccountingFactory.insert(:transaction_line, transaction: transaction, payee: payee2, amount: 500)

      assert {:ok, _deleted} = DeleteTransaction.call(scope, workspace, transaction.external_id)

      jobs =
        Repo.all(
          from(j in Oban.Job,
            where: j.worker == "PurseCraft.Accounting.Workers.CleanupOrphanedPayeesWorker",
            where: fragment("?->>'workspace_id' = ?", j.args, ^to_string(workspace.id))
          )
        )

      assert length(jobs) == 2
    end

    test "deduplicates payee IDs when scheduling cleanup", %{
      workspace: workspace,
      scope: scope,
      account: account
    } do
      payee = AccountingFactory.insert(:payee, workspace: workspace)

      transaction =
        AccountingFactory.insert(:transaction,
          workspace: workspace,
          account: account,
          payee: payee,
          amount: -1000
        )

      AccountingFactory.insert(:transaction_line, transaction: transaction, payee: payee, amount: 500)
      AccountingFactory.insert(:transaction_line, transaction: transaction, payee: payee, amount: 500)

      assert {:ok, _deleted} = DeleteTransaction.call(scope, workspace, transaction.external_id)

      jobs =
        Repo.all(
          from(j in Oban.Job,
            where: j.worker == "PurseCraft.Accounting.Workers.CleanupOrphanedPayeesWorker",
            where: fragment("?->>'workspace_id' = ?", j.args, ^to_string(workspace.id))
          )
        )

      assert length(jobs) == 1
    end

    test "does not schedule payee cleanup when transaction has no payee", %{
      workspace: workspace,
      scope: scope,
      account: account
    } do
      transaction =
        AccountingFactory.insert(:transaction,
          workspace: workspace,
          account: account,
          payee_id: nil,
          amount: -1000
        )

      AccountingFactory.insert(:transaction_line, transaction: transaction, payee_id: nil, amount: 1000)

      assert {:ok, _deleted} = DeleteTransaction.call(scope, workspace, transaction.external_id)

      jobs =
        Repo.all(
          from(j in Oban.Job,
            where: j.worker == "PurseCraft.Accounting.Workers.CleanupOrphanedPayeesWorker",
            where: fragment("?->>'workspace_id' = ?", j.args, ^to_string(workspace.id))
          )
        )

      assert Enum.empty?(jobs)
    end

    test "schedules search token deletion", %{
      workspace: workspace,
      scope: scope,
      account: account
    } do
      transaction = AccountingFactory.insert(:transaction, workspace: workspace, account: account)

      assert {:ok, deleted} = DeleteTransaction.call(scope, workspace, transaction.external_id)

      jobs =
        Repo.all(
          from(j in Oban.Job,
            where: j.worker == "PurseCraft.Search.Workers.DeleteTokensWorker",
            where: fragment("?->>'entity_type' = ?", j.args, "transaction"),
            where: fragment("?->>'entity_id' = ?", j.args, ^to_string(deleted.id))
          )
        )

      assert length(jobs) == 1
    end

    test "nilifies linked_transaction_id on linked transactions", %{
      workspace: workspace,
      scope: scope,
      account: account
    } do
      transaction1 = AccountingFactory.insert(:transaction, workspace: workspace, account: account)

      transaction2 =
        AccountingFactory.insert(:transaction,
          workspace: workspace,
          account: account,
          linked_transaction_id: transaction1.id
        )

      assert transaction2.linked_transaction_id == transaction1.id

      assert {:ok, _deleted} = DeleteTransaction.call(scope, workspace, transaction1.external_id)

      reloaded = Repo.get(Transaction, transaction2.id)
      assert reloaded.linked_transaction_id == nil
    end

    test "broadcasts transaction_deleted event", %{
      workspace: workspace,
      scope: scope,
      account: account
    } do
      transaction = AccountingFactory.insert(:transaction, workspace: workspace, account: account)

      PurseCraft.PubSub.subscribe_workspace(workspace)

      assert {:ok, deleted} = DeleteTransaction.call(scope, workspace, transaction.external_id)

      assert_received {:transaction_deleted, ^deleted}
    end
  end

  describe "call/3 - error cases" do
    test "returns not_found for invalid external_id", %{workspace: workspace, scope: scope} do
      assert {:error, :not_found} = DeleteTransaction.call(scope, workspace, Ecto.UUID.generate())
    end

    test "returns not_found for transaction from different workspace", %{
      workspace: workspace,
      scope: scope
    } do
      other_workspace = CoreFactory.insert(:workspace)
      other_account = AccountingFactory.insert(:account, workspace: other_workspace)

      transaction =
        AccountingFactory.insert(:transaction, workspace: other_workspace, account: other_account)

      assert {:error, :not_found} = DeleteTransaction.call(scope, workspace, transaction.external_id)
    end
  end
end
