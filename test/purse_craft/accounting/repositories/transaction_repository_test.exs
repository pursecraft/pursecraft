defmodule PurseCraft.Accounting.Repositories.TransactionRepositoryTest do
  use PurseCraft.DataCase, async: true

  alias Ecto.Association.NotLoaded
  alias Ecto.Changeset
  alias PurseCraft.Accounting.Repositories.TransactionRepository
  alias PurseCraft.AccountingFactory
  alias PurseCraft.CoreFactory

  setup do
    workspace = CoreFactory.insert(:workspace)
    account = AccountingFactory.insert(:account, workspace: workspace)

    {:ok, workspace: workspace, account: account}
  end

  describe "create/2" do
    test "handles transaction creation failure gracefully", %{workspace: workspace, account: account} do
      attrs = %{
        workspace_id: workspace.id,
        account_id: account.id,
        amount: 1000,
        # This will cause a validation error
        date: nil,
        lines: [
          %{amount: 1000, envelope_id: nil}
        ]
      }

      assert {:error, %Changeset{}} = TransactionRepository.create(attrs)
    end

    test "handles transaction line creation failure gracefully", %{workspace: workspace, account: account} do
      attrs = %{
        workspace_id: workspace.id,
        account_id: account.id,
        amount: 1000,
        date: Date.utc_today(),
        lines: [
          # This will cause a validation error
          %{amount: nil, envelope_id: nil}
        ]
      }

      assert {:error, %Changeset{}} = TransactionRepository.create(attrs)
    end

    test "creates transaction with preloaded associations", %{workspace: workspace, account: account} do
      attrs = %{
        workspace_id: workspace.id,
        account_id: account.id,
        amount: 1000,
        date: Date.utc_today(),
        lines: [
          %{amount: 1000, envelope_id: nil}
        ]
      }

      assert {:ok, transaction} = TransactionRepository.create(attrs, preload: [:account, :transaction_lines])

      assert %NotLoaded{} != transaction.account
      assert %NotLoaded{} != transaction.transaction_lines
    end
  end

  describe "get_by_external_id/2" do
    test "returns transaction when found", %{workspace: workspace, account: account} do
      transaction = AccountingFactory.insert(:transaction, workspace: workspace, account: account, amount: 1000)

      result = TransactionRepository.get_by_external_id(transaction.external_id)

      assert result.id == transaction.id
      assert result.external_id == transaction.external_id
      assert result.amount == 1000
    end

    test "returns nil when transaction not found" do
      result = TransactionRepository.get_by_external_id(Ecto.UUID.generate())

      assert result == nil
    end

    test "handles invalid UUID gracefully" do
      result = TransactionRepository.get_by_external_id(Ecto.UUID.generate())

      assert result == nil
    end

    test "returns transaction with preloaded associations when requested", %{
      workspace: workspace,
      account: account
    } do
      transaction = AccountingFactory.insert(:transaction, workspace: workspace, account: account)

      result = TransactionRepository.get_by_external_id(transaction.external_id, preload: [:account])

      assert result.id == transaction.id
      assert %NotLoaded{} != result.account
      assert result.account.id == account.id
    end

    test "returns transaction without preload by default", %{workspace: workspace, account: account} do
      transaction = AccountingFactory.insert(:transaction, workspace: workspace, account: account)

      result = TransactionRepository.get_by_external_id(transaction.external_id)

      assert result.id == transaction.id
      assert %NotLoaded{} = result.account
      assert %NotLoaded{} = result.workspace
    end
  end

  describe "list_by_workspace/2" do
    test "returns empty list when no transactions exist", %{workspace: workspace} do
      result = TransactionRepository.list_by_workspace(workspace.id)

      assert result == []
    end

    test "returns all transactions for workspace ordered by date descending", %{
      workspace: workspace,
      account: account
    } do
      transaction1 =
        AccountingFactory.insert(:transaction, workspace: workspace, account: account, date: ~D[2025-01-01])

      transaction2 =
        AccountingFactory.insert(:transaction, workspace: workspace, account: account, date: ~D[2025-01-03])

      transaction3 =
        AccountingFactory.insert(:transaction, workspace: workspace, account: account, date: ~D[2025-01-02])

      result = TransactionRepository.list_by_workspace(workspace.id)

      assert length(result) == 3
      assert [first, second, third] = result
      assert first.id == transaction2.id
      assert second.id == transaction3.id
      assert third.id == transaction1.id
    end

    test "only returns transactions for specified workspace", %{workspace: workspace, account: account} do
      other_workspace = CoreFactory.insert(:workspace)
      other_account = AccountingFactory.insert(:account, workspace: other_workspace)

      transaction1 = AccountingFactory.insert(:transaction, workspace: workspace, account: account)
      AccountingFactory.insert(:transaction, workspace: other_workspace, account: other_account)

      result = TransactionRepository.list_by_workspace(workspace.id)

      assert length(result) == 1
      assert [transaction] = result
      assert transaction.id == transaction1.id
      assert transaction.workspace_id == workspace.id
    end

    test "limits results when limit option provided", %{workspace: workspace, account: account} do
      AccountingFactory.insert(:transaction, workspace: workspace, account: account, date: ~D[2025-01-01])
      AccountingFactory.insert(:transaction, workspace: workspace, account: account, date: ~D[2025-01-02])
      AccountingFactory.insert(:transaction, workspace: workspace, account: account, date: ~D[2025-01-03])

      result = TransactionRepository.list_by_workspace(workspace.id, limit: 2)

      assert length(result) == 2
    end

    test "returns transactions with preloaded associations when requested", %{
      workspace: workspace,
      account: account
    } do
      AccountingFactory.insert(:transaction, workspace: workspace, account: account)

      result = TransactionRepository.list_by_workspace(workspace.id, preload: [:account])

      assert [transaction] = result
      assert %NotLoaded{} != transaction.account
      assert transaction.account.id == account.id
    end

    test "returns transactions without preload by default", %{workspace: workspace, account: account} do
      AccountingFactory.insert(:transaction, workspace: workspace, account: account)

      result = TransactionRepository.list_by_workspace(workspace.id)

      assert [transaction] = result
      assert %NotLoaded{} = transaction.account
      assert %NotLoaded{} = transaction.workspace
    end

    test "handles multiple options together", %{workspace: workspace, account: account} do
      AccountingFactory.insert(:transaction, workspace: workspace, account: account, date: ~D[2025-01-01])
      AccountingFactory.insert(:transaction, workspace: workspace, account: account, date: ~D[2025-01-02])
      AccountingFactory.insert(:transaction, workspace: workspace, account: account, date: ~D[2025-01-03])

      result = TransactionRepository.list_by_workspace(workspace.id, preload: [:account], limit: 2)

      assert length(result) == 2
      assert [first, second] = result
      assert %NotLoaded{} != first.account
      assert %NotLoaded{} != second.account
    end
  end
end
