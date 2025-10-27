defmodule PurseCraft.Accounting.Repositories.TransactionRepositoryTest do
  use PurseCraft.DataCase, async: true

  import Ecto.Query, only: [from: 2]

  alias Ecto.Association.NotLoaded
  alias Ecto.Changeset
  alias PurseCraft.Accounting.Repositories.TransactionRepository
  alias PurseCraft.Accounting.Schemas.Transaction
  alias PurseCraft.Accounting.Schemas.TransactionLine
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

    test "returns nil when transaction belongs to different workspace with workspace option", %{workspace: workspace} do
      other_workspace = CoreFactory.insert(:workspace)
      other_account = AccountingFactory.insert(:account, workspace: other_workspace)
      transaction = AccountingFactory.insert(:transaction, workspace: other_workspace, account: other_account)

      result = TransactionRepository.get_by_external_id(transaction.external_id, workspace: workspace)

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

  describe "update/2" do
    test "updates transaction with valid attrs", %{workspace: workspace, account: account} do
      transaction =
        AccountingFactory.insert(:transaction,
          workspace: workspace,
          account: account,
          date: ~D[2025-01-01],
          amount: 1000,
          memo: "Original memo"
        )

      attrs = %{date: ~D[2025-01-02], amount: 2000, memo: "Updated memo"}

      assert {:ok, updated} = TransactionRepository.update(transaction, attrs)
      assert updated.id == transaction.id
      assert updated.date == ~D[2025-01-02]
      assert updated.amount == 2000
      assert updated.memo == "Updated memo"
    end

    test "returns error with invalid date", %{workspace: workspace, account: account} do
      transaction = AccountingFactory.insert(:transaction, workspace: workspace, account: account)

      assert {:error, %Changeset{}} = TransactionRepository.update(transaction, %{date: nil})
    end

    test "returns error with invalid amount", %{workspace: workspace, account: account} do
      transaction = AccountingFactory.insert(:transaction, workspace: workspace, account: account)

      assert {:error, %Changeset{}} = TransactionRepository.update(transaction, %{amount: nil})
    end

    test "updates memo field", %{workspace: workspace, account: account} do
      transaction = AccountingFactory.insert(:transaction, workspace: workspace, account: account, memo: "Original")

      assert {:ok, updated} = TransactionRepository.update(transaction, %{memo: "Updated memo"})
      assert updated.memo == "Updated memo"
      assert updated.date == transaction.date
      assert updated.amount == transaction.amount
    end

    test "updates cleared field", %{workspace: workspace, account: account} do
      transaction =
        AccountingFactory.insert(:transaction, workspace: workspace, account: account, cleared: false)

      assert {:ok, updated} = TransactionRepository.update(transaction, %{cleared: true})
      assert updated.cleared == true
    end

    test "updates payee_id", %{workspace: workspace, account: account} do
      payee = AccountingFactory.insert(:payee, workspace: workspace)
      transaction = AccountingFactory.insert(:transaction, workspace: workspace, account: account, payee_id: nil)

      assert {:ok, updated} = TransactionRepository.update(transaction, %{payee_id: payee.id})
      assert updated.payee_id == payee.id
    end

    test "sets payee_id to nil", %{workspace: workspace, account: account} do
      payee = AccountingFactory.insert(:payee, workspace: workspace)

      transaction =
        AccountingFactory.insert(:transaction, workspace: workspace, account: account, payee_id: payee.id)

      assert {:ok, updated} = TransactionRepository.update(transaction, %{payee_id: nil})
      assert updated.payee_id == nil
    end

    test "does not update account_id", %{workspace: workspace, account: account} do
      other_account = AccountingFactory.insert(:account, workspace: workspace)

      transaction =
        AccountingFactory.insert(:transaction, workspace: workspace, account: account, amount: 1000)

      assert {:ok, updated} = TransactionRepository.update(transaction, %{account_id: other_account.id})
      assert updated.account_id == account.id
    end

    test "does not update workspace_id", %{workspace: workspace, account: account} do
      other_workspace = CoreFactory.insert(:workspace)

      transaction =
        AccountingFactory.insert(:transaction, workspace: workspace, account: account, amount: 1000)

      assert {:ok, updated} = TransactionRepository.update(transaction, %{workspace_id: other_workspace.id})
      assert updated.workspace_id == workspace.id
    end
  end

  describe "update_with_lines/4" do
    test "updates transaction and replaces all lines atomically", %{workspace: workspace, account: account} do
      {:ok, transaction} =
        TransactionRepository.create(%{
          workspace_id: workspace.id,
          account_id: account.id,
          date: ~D[2025-01-01],
          amount: 1000,
          lines: [%{amount: 1000, envelope_id: nil}]
        })

      old_line_id = hd(transaction.transaction_lines).id

      attrs = %{date: ~D[2025-01-02], amount: 2000}
      lines_attrs = [%{amount: 2000, envelope_id: nil}]

      assert {:ok, updated} = TransactionRepository.update_with_lines(transaction, attrs, lines_attrs)
      assert updated.date == ~D[2025-01-02]
      assert updated.amount == 2000
      assert length(updated.transaction_lines) == 1
      assert hd(updated.transaction_lines).id != old_line_id
    end

    test "updates from single to split transaction", %{workspace: workspace, account: account} do
      {:ok, transaction} =
        TransactionRepository.create(%{
          workspace_id: workspace.id,
          account_id: account.id,
          date: Date.utc_today(),
          amount: 5000,
          lines: [%{amount: 5000, envelope_id: nil}]
        })

      attrs = %{amount: 5000}
      lines_attrs = [%{amount: 3000, envelope_id: nil}, %{amount: 2000, envelope_id: nil}]

      assert {:ok, updated} = TransactionRepository.update_with_lines(transaction, attrs, lines_attrs)
      assert length(updated.transaction_lines) == 2
      assert Enum.at(updated.transaction_lines, 0).amount == 3000
      assert Enum.at(updated.transaction_lines, 1).amount == 2000
    end

    test "updates from split to single transaction", %{workspace: workspace, account: account} do
      {:ok, transaction} =
        TransactionRepository.create(%{
          workspace_id: workspace.id,
          account_id: account.id,
          date: Date.utc_today(),
          amount: 5000,
          lines: [%{amount: 3000, envelope_id: nil}, %{amount: 2000, envelope_id: nil}]
        })

      attrs = %{amount: 5000}
      lines_attrs = [%{amount: 5000, envelope_id: nil}]

      assert {:ok, updated} = TransactionRepository.update_with_lines(transaction, attrs, lines_attrs)
      assert length(updated.transaction_lines) == 1
      assert hd(updated.transaction_lines).amount == 5000
    end

    test "updates line amounts", %{workspace: workspace, account: account} do
      {:ok, transaction} =
        TransactionRepository.create(%{
          workspace_id: workspace.id,
          account_id: account.id,
          date: Date.utc_today(),
          amount: 1000,
          lines: [%{amount: 1000, envelope_id: nil}]
        })

      attrs = %{amount: 2500}
      lines_attrs = [%{amount: 2500, envelope_id: nil}]

      assert {:ok, updated} = TransactionRepository.update_with_lines(transaction, attrs, lines_attrs)
      assert hd(updated.transaction_lines).amount == 2500
    end

    test "updates line memos", %{workspace: workspace, account: account} do
      {:ok, transaction} =
        TransactionRepository.create(%{
          workspace_id: workspace.id,
          account_id: account.id,
          date: Date.utc_today(),
          amount: 1000,
          lines: [%{amount: 1000, envelope_id: nil, memo: "Original"}]
        })

      attrs = %{}
      lines_attrs = [%{amount: 1000, envelope_id: nil, memo: "Updated"}]

      assert {:ok, updated} = TransactionRepository.update_with_lines(transaction, attrs, lines_attrs)
      assert hd(updated.transaction_lines).memo == "Updated"
    end

    test "updates with Ready to Assign lines", %{workspace: workspace, account: account} do
      {:ok, transaction} =
        TransactionRepository.create(%{
          workspace_id: workspace.id,
          account_id: account.id,
          date: Date.utc_today(),
          amount: 1000,
          lines: [%{amount: 1000, envelope_id: nil}]
        })

      attrs = %{}
      lines_attrs = [%{amount: 1000, envelope_id: nil}]

      assert {:ok, updated} = TransactionRepository.update_with_lines(transaction, attrs, lines_attrs)
      assert hd(updated.transaction_lines).envelope_id == nil
    end

    test "preloads transaction_lines by default", %{workspace: workspace, account: account} do
      {:ok, transaction} =
        TransactionRepository.create(%{
          workspace_id: workspace.id,
          account_id: account.id,
          date: Date.utc_today(),
          amount: 1000,
          lines: [%{amount: 1000, envelope_id: nil}]
        })

      attrs = %{}
      lines_attrs = [%{amount: 1000, envelope_id: nil}]

      assert {:ok, updated} = TransactionRepository.update_with_lines(transaction, attrs, lines_attrs)
      assert %NotLoaded{} != updated.transaction_lines
      assert length(updated.transaction_lines) == 1
    end

    test "supports custom preload options", %{workspace: workspace, account: account} do
      {:ok, transaction} =
        TransactionRepository.create(%{
          workspace_id: workspace.id,
          account_id: account.id,
          date: Date.utc_today(),
          amount: 1000,
          lines: [%{amount: 1000, envelope_id: nil}]
        })

      attrs = %{}
      lines_attrs = [%{amount: 1000, envelope_id: nil}]

      assert {:ok, updated} =
               TransactionRepository.update_with_lines(transaction, attrs, lines_attrs,
                 preload: [:account, :transaction_lines]
               )

      assert %NotLoaded{} != updated.account
      assert %NotLoaded{} != updated.transaction_lines
    end

    test "returns error when lines array is empty", %{workspace: workspace, account: account} do
      {:ok, transaction} =
        TransactionRepository.create(%{
          workspace_id: workspace.id,
          account_id: account.id,
          date: Date.utc_today(),
          amount: 1000,
          lines: [%{amount: 1000, envelope_id: nil}]
        })

      assert {:error, %Changeset{}} = TransactionRepository.update_with_lines(transaction, %{}, [])
    end

    test "returns error when transaction attrs invalid", %{workspace: workspace, account: account} do
      {:ok, transaction} =
        TransactionRepository.create(%{
          workspace_id: workspace.id,
          account_id: account.id,
          date: Date.utc_today(),
          amount: 1000,
          lines: [%{amount: 1000, envelope_id: nil}]
        })

      attrs = %{date: nil}
      lines_attrs = [%{amount: 1000, envelope_id: nil}]

      assert {:error, %Changeset{}} = TransactionRepository.update_with_lines(transaction, attrs, lines_attrs)
    end

    test "returns error when line attrs invalid", %{workspace: workspace, account: account} do
      {:ok, transaction} =
        TransactionRepository.create(%{
          workspace_id: workspace.id,
          account_id: account.id,
          date: Date.utc_today(),
          amount: 1000,
          lines: [%{amount: 1000, envelope_id: nil}]
        })

      attrs = %{}
      lines_attrs = [%{amount: nil, envelope_id: nil}]

      assert {:error, %Changeset{}} = TransactionRepository.update_with_lines(transaction, attrs, lines_attrs)
    end

    test "rolls back all changes on error", %{workspace: workspace, account: account} do
      {:ok, transaction} =
        TransactionRepository.create(%{
          workspace_id: workspace.id,
          account_id: account.id,
          date: Date.utc_today(),
          amount: 1000,
          memo: "Original",
          lines: [%{amount: 1000, envelope_id: nil}]
        })

      line_count_query = from(l in TransactionLine, where: l.transaction_id == ^transaction.id, select: count(l.id))
      original_line_count = Repo.one(line_count_query)

      attrs = %{memo: "Updated"}
      lines_attrs = [%{amount: nil, envelope_id: nil}]

      assert {:error, %Changeset{}} = TransactionRepository.update_with_lines(transaction, attrs, lines_attrs)

      reloaded = Repo.get(Transaction, transaction.id)
      assert reloaded.memo == "Original"

      line_count = Repo.one(line_count_query)

      assert line_count == original_line_count
    end

    test "verifies old lines deleted after success", %{workspace: workspace, account: account} do
      {:ok, transaction} =
        TransactionRepository.create(%{
          workspace_id: workspace.id,
          account_id: account.id,
          date: Date.utc_today(),
          amount: 1000,
          lines: [%{amount: 1000, envelope_id: nil}]
        })

      old_line_id = hd(transaction.transaction_lines).id

      attrs = %{}
      lines_attrs = [%{amount: 1000, envelope_id: nil}]

      assert {:ok, _updated} = TransactionRepository.update_with_lines(transaction, attrs, lines_attrs)

      assert Repo.get(TransactionLine, old_line_id) == nil
    end

    test "handles foreign key constraint violations", %{workspace: workspace, account: account} do
      {:ok, transaction} =
        TransactionRepository.create(%{
          workspace_id: workspace.id,
          account_id: account.id,
          date: Date.utc_today(),
          amount: 1000,
          lines: [%{amount: 1000, envelope_id: nil}]
        })

      attrs = %{}
      lines_attrs = [%{amount: 1000, envelope_id: 999_999}]

      assert {:error, %Changeset{}} = TransactionRepository.update_with_lines(transaction, attrs, lines_attrs)
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

  describe "delete/1" do
    test "deletes transaction successfully", %{workspace: workspace, account: account} do
      transaction = AccountingFactory.insert(:transaction, workspace: workspace, account: account)

      assert {:ok, deleted} = TransactionRepository.delete(transaction)
      assert deleted.id == transaction.id
      assert Repo.get(Transaction, transaction.id) == nil
    end

    test "cascade deletes transaction lines", %{workspace: workspace, account: account} do
      {:ok, transaction} =
        TransactionRepository.create(%{
          workspace_id: workspace.id,
          account_id: account.id,
          date: Date.utc_today(),
          amount: 1000,
          lines: [
            %{amount: 500, envelope_id: nil},
            %{amount: 500, envelope_id: nil}
          ]
        })

      line_ids = Enum.map(transaction.transaction_lines, & &1.id)

      assert {:ok, _deleted} = TransactionRepository.delete(transaction)

      Enum.each(line_ids, fn line_id ->
        assert Repo.get(TransactionLine, line_id) == nil
      end)
    end

    test "nilifies linked_transaction_id on linked transactions", %{workspace: workspace, account: account} do
      transaction1 = AccountingFactory.insert(:transaction, workspace: workspace, account: account)

      transaction2 =
        AccountingFactory.insert(:transaction,
          workspace: workspace,
          account: account,
          linked_transaction_id: transaction1.id
        )

      assert transaction2.linked_transaction_id == transaction1.id

      assert {:ok, _deleted} = TransactionRepository.delete(transaction1)

      reloaded = Repo.get(Transaction, transaction2.id)
      assert reloaded.linked_transaction_id == nil
    end

    test "returns error when trying to delete already deleted transaction", %{workspace: workspace, account: account} do
      transaction = AccountingFactory.insert(:transaction, workspace: workspace, account: account)

      assert {:ok, _deleted} = TransactionRepository.delete(transaction)

      assert {:error, changeset} = TransactionRepository.delete(transaction)
      assert changeset.errors[:id] == {"is stale", [stale: true]}
    end
  end
end
