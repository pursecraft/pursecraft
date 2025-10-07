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
end
