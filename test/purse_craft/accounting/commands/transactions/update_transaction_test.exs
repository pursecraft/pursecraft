defmodule PurseCraft.Accounting.Commands.Transactions.UpdateTransactionTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Accounting.Commands.Transactions.UpdateTransaction
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

    transaction =
      AccountingFactory.insert(:transaction,
        workspace: workspace,
        account: account,
        payee: payee,
        amount: -5000,
        memo: "Original memo",
        cleared: false
      )

    transaction_line =
      AccountingFactory.insert(:transaction_line,
        transaction: transaction,
        envelope: envelope,
        payee: payee,
        amount: 5000
      )

    {:ok,
     workspace: workspace,
     scope: scope,
     account: account,
     payee: payee,
     envelope: envelope,
     transaction: transaction,
     transaction_line: transaction_line}
  end

  describe "call/4 - happy path updates" do
    test "updates memo only", %{
      workspace: workspace,
      scope: scope,
      transaction: transaction
    } do
      attrs = %{memo: "Updated memo"}

      assert {:ok, %Transaction{} = updated} =
               UpdateTransaction.call(scope, workspace, transaction.external_id, attrs)

      assert updated.memo == "Updated memo"
      assert updated.cleared == transaction.cleared
      assert updated.payee_id == transaction.payee_id
    end

    test "updates cleared status only", %{
      workspace: workspace,
      scope: scope,
      transaction: transaction
    } do
      attrs = %{cleared: true}

      assert {:ok, %Transaction{} = updated} =
               UpdateTransaction.call(scope, workspace, transaction.external_id, attrs)

      assert updated.cleared == true
      assert updated.memo == transaction.memo
      assert updated.payee_id == transaction.payee_id
    end

    test "updates payee_id only", %{
      workspace: workspace,
      scope: scope,
      transaction: transaction
    } do
      new_payee = AccountingFactory.insert(:payee, workspace: workspace)
      attrs = %{payee_id: new_payee.id}

      assert {:ok, %Transaction{} = updated} =
               UpdateTransaction.call(scope, workspace, transaction.external_id, attrs)

      assert updated.payee_id == new_payee.id
      assert updated.memo == transaction.memo
      assert updated.cleared == transaction.cleared
    end

    test "updates payee to nil", %{
      workspace: workspace,
      scope: scope,
      transaction: transaction
    } do
      attrs = %{payee_id: nil}

      assert {:ok, %Transaction{} = updated} =
               UpdateTransaction.call(scope, workspace, transaction.external_id, attrs)

      assert updated.payee_id == nil
    end

    test "updates multiple fields at once", %{
      workspace: workspace,
      scope: scope,
      transaction: transaction
    } do
      new_payee = AccountingFactory.insert(:payee, workspace: workspace)
      attrs = %{memo: "New memo", cleared: true, payee_id: new_payee.id}

      assert {:ok, %Transaction{} = updated} =
               UpdateTransaction.call(scope, workspace, transaction.external_id, attrs)

      assert updated.memo == "New memo"
      assert updated.cleared == true
      assert updated.payee_id == new_payee.id
    end

    test "updates transaction lines with single line", %{
      workspace: workspace,
      scope: scope,
      transaction: transaction,
      envelope: envelope
    } do
      attrs = %{
        lines: [
          %{amount: 5000, envelope_id: envelope.id, memo: "Updated line"}
        ]
      }

      assert {:ok, %Transaction{} = updated} =
               UpdateTransaction.call(scope, workspace, transaction.external_id, attrs)

      assert length(updated.transaction_lines) == 1
      line = hd(updated.transaction_lines)
      assert line.amount == 5000
      assert line.envelope_id == envelope.id
      assert line.memo == "Updated line"
    end

    test "updates transaction lines from single to split", %{
      workspace: workspace,
      scope: scope,
      transaction: transaction,
      envelope: envelope
    } do
      category2 = BudgetingFactory.insert(:category, workspace: workspace)
      envelope2 = BudgetingFactory.insert(:envelope, category: category2)

      attrs = %{
        lines: [
          %{amount: 3000, envelope_id: envelope.id, memo: "Part 1"},
          %{amount: 2000, envelope_id: envelope2.id, memo: "Part 2"}
        ]
      }

      assert {:ok, %Transaction{} = updated} =
               UpdateTransaction.call(scope, workspace, transaction.external_id, attrs)

      assert length(updated.transaction_lines) == 2

      lines = Enum.sort_by(updated.transaction_lines, & &1.amount)
      [line1, line2] = lines

      assert line1.amount == 2000
      assert line1.envelope_id == envelope2.id
      assert line1.memo == "Part 2"

      assert line2.amount == 3000
      assert line2.envelope_id == envelope.id
      assert line2.memo == "Part 1"
    end

    test "updates transaction lines with line-level payee changes", %{
      workspace: workspace,
      scope: scope,
      transaction: transaction,
      envelope: envelope
    } do
      new_payee = AccountingFactory.insert(:payee, workspace: workspace)

      attrs = %{
        lines: [
          %{amount: 5000, envelope_id: envelope.id, payee_id: new_payee.id}
        ]
      }

      assert {:ok, %Transaction{} = updated} =
               UpdateTransaction.call(scope, workspace, transaction.external_id, attrs)

      line = hd(updated.transaction_lines)
      assert line.payee_id == new_payee.id
    end

    test "updates transaction lines to ready to assign", %{
      workspace: workspace,
      scope: scope,
      transaction: transaction
    } do
      attrs = %{
        lines: [
          %{amount: 5000, envelope_id: nil}
        ]
      }

      assert {:ok, %Transaction{} = updated} =
               UpdateTransaction.call(scope, workspace, transaction.external_id, attrs)

      line = hd(updated.transaction_lines)
      assert line.envelope_id == nil
    end
  end

  describe "call/4 - authorization" do
    test "owner can update", %{
      workspace: workspace,
      scope: scope,
      transaction: transaction
    } do
      attrs = %{memo: "Owner update"}

      assert {:ok, %Transaction{}} =
               UpdateTransaction.call(scope, workspace, transaction.external_id, attrs)
    end

    test "editor can update", %{
      workspace: workspace,
      transaction: transaction
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{memo: "Editor update"}

      assert {:ok, %Transaction{}} =
               UpdateTransaction.call(scope, workspace, transaction.external_id, attrs)
    end

    test "commenter cannot update", %{
      workspace: workspace,
      transaction: transaction
    } do
      user = IdentityFactory.insert(:user)

      CoreFactory.insert(:workspace_user,
        workspace_id: workspace.id,
        user_id: user.id,
        role: :commenter
      )

      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{memo: "Commenter update"}

      assert {:error, :unauthorized} =
               UpdateTransaction.call(scope, workspace, transaction.external_id, attrs)
    end

    test "no workspace association cannot update", %{
      workspace: workspace,
      transaction: transaction
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{memo: "Unauthorized update"}

      assert {:error, :unauthorized} =
               UpdateTransaction.call(scope, workspace, transaction.external_id, attrs)
    end
  end

  describe "call/4 - validation errors" do
    test "returns not_found for non-existent transaction", %{
      workspace: workspace,
      scope: scope
    } do
      attrs = %{memo: "Update"}

      assert {:error, :not_found} =
               UpdateTransaction.call(scope, workspace, Ecto.UUID.generate(), attrs)
    end

    test "returns not_found for transaction in different workspace", %{
      scope: scope,
      transaction: transaction
    } do
      other_workspace = CoreFactory.insert(:workspace)
      attrs = %{memo: "Update"}

      assert {:error, :not_found} =
               UpdateTransaction.call(scope, other_workspace, transaction.external_id, attrs)
    end

    test "returns error for empty lines array", %{
      workspace: workspace,
      scope: scope,
      transaction: transaction
    } do
      attrs = %{lines: []}

      assert {:error, :empty_lines} =
               UpdateTransaction.call(scope, workspace, transaction.external_id, attrs)
    end

    test "returns amount_mismatch when line sum does not equal transaction amount", %{
      workspace: workspace,
      scope: scope,
      transaction: transaction,
      envelope: envelope
    } do
      attrs = %{
        lines: [
          %{amount: 3000, envelope_id: envelope.id}
        ]
      }

      assert {:error, :amount_mismatch} =
               UpdateTransaction.call(scope, workspace, transaction.external_id, attrs)
    end

    test "succeeds when line sum equals transaction amount", %{
      workspace: workspace,
      scope: scope,
      transaction: transaction,
      envelope: envelope
    } do
      attrs = %{
        lines: [
          %{amount: 5000, envelope_id: envelope.id}
        ]
      }

      assert {:ok, %Transaction{}} =
               UpdateTransaction.call(scope, workspace, transaction.external_id, attrs)
    end
  end

  describe "call/4 - immutable fields" do
    test "returns error when trying to update account_id", %{
      workspace: workspace,
      scope: scope,
      transaction: transaction,
      account: account
    } do
      other_account = AccountingFactory.insert(:account, workspace: workspace)
      attrs = %{account_id: other_account.id}

      assert {:error, :immutable_field} =
               UpdateTransaction.call(scope, workspace, transaction.external_id, attrs)

      reloaded = Repo.get(Transaction, transaction.id)
      assert reloaded.account_id == account.id
    end

    test "returns error when trying to update workspace_id", %{
      workspace: workspace,
      scope: scope,
      transaction: transaction
    } do
      other_workspace = CoreFactory.insert(:workspace)
      attrs = %{workspace_id: other_workspace.id}

      assert {:error, :immutable_field} =
               UpdateTransaction.call(scope, workspace, transaction.external_id, attrs)

      reloaded = Repo.get(Transaction, transaction.id)
      assert reloaded.workspace_id == workspace.id
    end

    test "returns error when trying to update date", %{
      workspace: workspace,
      scope: scope,
      transaction: transaction
    } do
      new_date = Date.add(transaction.date, 1)
      attrs = %{date: new_date}

      assert {:error, :immutable_field} =
               UpdateTransaction.call(scope, workspace, transaction.external_id, attrs)

      reloaded = Repo.get(Transaction, transaction.id)
      assert reloaded.date == transaction.date
    end

    test "returns error when trying to update amount directly", %{
      workspace: workspace,
      scope: scope,
      transaction: transaction
    } do
      attrs = %{amount: -10_000}

      assert {:error, :immutable_field} =
               UpdateTransaction.call(scope, workspace, transaction.external_id, attrs)

      reloaded = Repo.get(Transaction, transaction.id)
      assert reloaded.amount == transaction.amount
    end
  end
end
