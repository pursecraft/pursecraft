defmodule PurseCraft.Accounting.Commands.Transactions.CreateTransactionTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Accounting.Commands.Transactions.CreateTransaction
  alias PurseCraft.Accounting.Schemas.Transaction
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
    payee = AccountingFactory.insert(:payee, workspace: workspace)

    category = BudgetingFactory.insert(:category, workspace: workspace)
    envelope = BudgetingFactory.insert(:envelope, category: category)

    {:ok, workspace: workspace, scope: scope, account: account, payee: payee, envelope: envelope}
  end

  describe "call/3" do
    test "creates simple expense transaction with source/destination/with format", %{
      workspace: workspace,
      scope: scope,
      account: account,
      payee: payee,
      envelope: envelope
    } do
      attrs = %{
        source: account,
        destination: envelope,
        with: payee,
        amount: 2500,
        memo: "Test transaction"
      }

      assert {:ok, %Transaction{} = transaction} = CreateTransaction.call(scope, workspace, attrs)

      # Verify transaction fields
      # Negative because money flows out of account
      assert transaction.amount == -2500
      assert transaction.account_id == account.id
      assert transaction.payee_id == payee.id
      assert transaction.workspace_id == workspace.id
      assert transaction.memo == "Test transaction"
      assert transaction.date == Date.utc_today()

      # Verify transaction line was created
      assert length(transaction.transaction_lines) == 1
      line = hd(transaction.transaction_lines)
      # Positive amount for envelope allocation
      assert line.amount == 2500
      assert line.envelope_id == envelope.id
      # Inherits transaction-level payee
      assert line.payee_id == payee.id
      # No line-level memo
      assert line.memo == nil
    end

    test "creates split transaction with multiple lines", %{
      workspace: workspace,
      scope: scope,
      account: account,
      payee: payee,
      envelope: envelope
    } do
      category2 = BudgetingFactory.insert(:category, workspace: workspace)
      envelope2 = BudgetingFactory.insert(:envelope, category: category2)

      attrs = %{
        source: account,
        with: payee,
        memo: "Split transaction",
        lines: [
          %{destination: envelope, amount: 3000, memo: "Groceries"},
          %{destination: envelope2, amount: 2000, memo: "Gas"}
        ]
      }

      assert {:ok, %Transaction{} = transaction} = CreateTransaction.call(scope, workspace, attrs)

      # Verify transaction fields
      # Total outflow from account
      assert transaction.amount == -5000
      assert transaction.account_id == account.id
      assert transaction.payee_id == payee.id
      assert transaction.memo == "Split transaction"

      # Verify transaction lines
      assert length(transaction.transaction_lines) == 2

      lines = Enum.sort_by(transaction.transaction_lines, & &1.amount)
      [line1, line2] = lines

      assert line1.amount == 2000
      assert line1.envelope_id == envelope2.id
      assert line1.memo == "Gas"
      # Inherits transaction-level payee
      assert line1.payee_id == payee.id

      assert line2.amount == 3000
      assert line2.envelope_id == envelope.id
      assert line2.memo == "Groceries"
      # Inherits transaction-level payee
      assert line2.payee_id == payee.id
    end

    test "creates income transaction to Ready to Assign", %{
      workspace: workspace,
      scope: scope,
      account: account,
      payee: payee
    } do
      attrs = %{
        source: payee,
        destination: account,
        with: :ready_to_assign,
        amount: 300_000,
        memo: "Salary"
      }

      assert {:ok, %Transaction{} = transaction} = CreateTransaction.call(scope, workspace, attrs)

      # Verify transaction fields
      # Positive inflow to account
      assert transaction.amount == 300_000
      assert transaction.account_id == account.id
      assert transaction.payee_id == payee.id
      assert transaction.memo == "Salary"

      # Verify Ready to Assign line
      assert length(transaction.transaction_lines) == 1
      line = hd(transaction.transaction_lines)
      assert line.amount == 300_000
      # Ready to Assign
      assert line.envelope_id == nil
    end

    test "with commenter role returns unauthorized error", %{
      workspace: workspace,
      account: account,
      payee: payee,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{
        source: account,
        destination: envelope,
        with: payee,
        amount: 2500
      }

      assert {:error, :unauthorized} = CreateTransaction.call(scope, workspace, attrs)
    end

    test "with no workspace association returns unauthorized error", %{
      workspace: workspace,
      account: account,
      payee: payee,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{
        source: account,
        destination: envelope,
        with: payee,
        amount: 2500
      }

      assert {:error, :unauthorized} = CreateTransaction.call(scope, workspace, attrs)
    end

    test "creates income transaction from payee source to account destination", %{
      workspace: workspace,
      scope: scope,
      account: account,
      payee: payee
    } do
      attrs = %{
        source: payee,
        lines: [
          %{destination: account, amount: 5000}
        ]
      }

      assert {:ok, %Transaction{} = transaction} = CreateTransaction.call(scope, workspace, attrs)

      assert transaction.amount == 5000
      assert transaction.account_id == account.id
      assert transaction.payee_id == payee.id
    end

    test "creates transaction with ready_to_assign destination", %{
      workspace: workspace,
      scope: scope,
      account: account,
      payee: payee
    } do
      attrs = %{
        source: account,
        lines: [
          %{destination: :ready_to_assign, amount: 1000, with: payee}
        ]
      }

      assert {:ok, %Transaction{} = transaction} = CreateTransaction.call(scope, workspace, attrs)

      assert transaction.account_id == account.id
      assert transaction.amount == -1000
      assert length(transaction.transaction_lines) == 1

      line = hd(transaction.transaction_lines)
      assert line.envelope_id == nil
      assert line.payee_id == payee.id
    end

    test "returns error for invalid transaction structure", %{
      workspace: workspace,
      scope: scope,
      payee: payee
    } do
      attrs = %{
        lines: [
          %{destination: payee, amount: 1000}
        ],
        memo: "Invalid transaction"
      }

      assert {:error, "Cannot determine account impact - need either source account or destination account"} =
               CreateTransaction.call(scope, workspace, attrs)
    end

    test "creates transaction without payee information", %{
      workspace: workspace,
      scope: scope,
      account: account,
      envelope: envelope
    } do
      attrs = %{
        source: account,
        destination: envelope,
        amount: 1000,
        memo: "No payee transaction"
      }

      assert {:ok, %Transaction{} = transaction} = CreateTransaction.call(scope, workspace, attrs)

      assert transaction.payee_id == nil
      assert transaction.account_id == account.id
      assert transaction.amount == -1000
    end

    test "creates transaction with lines but no transaction-level 'with'", %{
      workspace: workspace,
      scope: scope,
      account: account,
      envelope: envelope,
      payee: payee
    } do
      attrs = %{
        source: account,
        lines: [
          %{destination: envelope, amount: 1500, with: payee}
        ]
      }

      assert {:ok, %Transaction{} = transaction} = CreateTransaction.call(scope, workspace, attrs)

      assert transaction.account_id == account.id
      assert transaction.amount == -1500
      assert length(transaction.transaction_lines) == 1

      line = hd(transaction.transaction_lines)
      assert line.payee_id == payee.id
    end

    test "creates transaction with non-envelope destination", %{
      workspace: workspace,
      scope: scope,
      payee: payee
    } do
      other_account = AccountingFactory.insert(:account, workspace: workspace)

      attrs = %{
        source: payee,
        lines: [
          %{destination: other_account, amount: 2000}
        ]
      }

      assert {:ok, %Transaction{} = transaction} = CreateTransaction.call(scope, workspace, attrs)

      assert transaction.account_id == other_account.id
      assert transaction.amount == 2000
      assert length(transaction.transaction_lines) == 1

      line = hd(transaction.transaction_lines)
      assert line.envelope_id == nil
    end

    test "creates income transaction with payee source and account destination", %{
      workspace: workspace,
      scope: scope,
      payee: payee,
      account: account
    } do
      attrs = %{
        source: payee,
        lines: [
          %{destination: account, amount: 1500}
        ],
        memo: "Income from payee"
      }

      assert {:ok, %Transaction{} = transaction} = CreateTransaction.call(scope, workspace, attrs)

      assert transaction.account_id == account.id
      assert transaction.amount == 1500
      assert transaction.payee_id == payee.id
      assert transaction.memo == "Income from payee"
      assert length(transaction.transaction_lines) == 1
    end
  end
end
