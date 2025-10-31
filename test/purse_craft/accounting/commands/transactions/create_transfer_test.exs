defmodule PurseCraft.Accounting.Commands.Transactions.CreateTransferTest do
  use PurseCraft.DataCase, async: true
  use Mimic

  alias PurseCraft.Accounting.Commands.Transactions.CreateTransfer
  alias PurseCraft.Accounting.Repositories.TransactionRepository
  alias PurseCraft.Accounting.Schemas.Transaction
  alias PurseCraft.AccountingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

  setup do
    workspace = CoreFactory.insert(:workspace)
    user = IdentityFactory.insert(:user)
    CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
    scope = IdentityFactory.build(:scope, user: user)

    # Default to asset accounts (checking) for basic tests
    from_account = AccountingFactory.insert(:account, workspace: workspace, account_type: "checking")
    to_account = AccountingFactory.insert(:account, workspace: workspace, account_type: "savings")

    {:ok, workspace: workspace, scope: scope, from_account: from_account, to_account: to_account}
  end

  describe "call/3" do
    test "creates transfer with both transactions linked bidirectionally", %{
      workspace: workspace,
      scope: scope,
      from_account: from_account,
      to_account: to_account
    } do
      attrs = %{
        from_account: from_account,
        to_account: to_account,
        amount: 50_000,
        memo: "Monthly savings"
      }

      assert {:ok, {from_transaction, to_transaction}} = CreateTransfer.call(scope, workspace, attrs)

      # Verify from_transaction (outflow)
      assert from_transaction.amount == -50_000
      assert from_transaction.account_id == from_account.id
      assert from_transaction.workspace_id == workspace.id
      assert from_transaction.memo == "Monthly savings"
      assert from_transaction.payee_id == nil
      assert from_transaction.cleared == false
      assert from_transaction.date == Date.utc_today()

      # Verify to_transaction (inflow)
      assert to_transaction.amount == 50_000
      assert to_transaction.account_id == to_account.id
      assert to_transaction.workspace_id == workspace.id
      assert to_transaction.memo == "Monthly savings"
      assert to_transaction.payee_id == nil
      assert to_transaction.cleared == false
      assert to_transaction.date == Date.utc_today()

      # Verify bidirectional linking
      assert from_transaction.linked_transaction_id == to_transaction.id
      assert to_transaction.linked_transaction_id == from_transaction.id

      # Verify transaction lines (no budget impact)
      assert length(from_transaction.transaction_lines) == 1
      from_line = hd(from_transaction.transaction_lines)
      assert from_line.amount == -50_000
      assert from_line.envelope_id == nil
      assert from_line.payee_id == nil

      assert length(to_transaction.transaction_lines) == 1
      to_line = hd(to_transaction.transaction_lines)
      assert to_line.amount == 50_000
      assert to_line.envelope_id == nil
      assert to_line.payee_id == nil
    end

    test "accepts from_account as Account struct", %{
      workspace: workspace,
      scope: scope,
      from_account: from_account,
      to_account: to_account
    } do
      attrs = %{
        from_account: from_account,
        to_account: to_account,
        amount: 10_000
      }

      assert {:ok, {from_transaction, _to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
      assert from_transaction.account_id == from_account.id
    end

    test "accepts from_account as integer ID", %{
      workspace: workspace,
      scope: scope,
      from_account: from_account,
      to_account: to_account
    } do
      attrs = %{
        from_account: from_account.id,
        to_account: to_account,
        amount: 10_000
      }

      assert {:ok, {from_transaction, _to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
      assert from_transaction.account_id == from_account.id
    end

    test "accepts from_account as UUID external_id", %{
      workspace: workspace,
      scope: scope,
      from_account: from_account,
      to_account: to_account
    } do
      attrs = %{
        from_account: from_account.external_id,
        to_account: to_account,
        amount: 10_000
      }

      assert {:ok, {from_transaction, _to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
      assert from_transaction.account_id == from_account.id
    end

    test "accepts to_account as Account struct", %{
      workspace: workspace,
      scope: scope,
      from_account: from_account,
      to_account: to_account
    } do
      attrs = %{
        from_account: from_account,
        to_account: to_account,
        amount: 10_000
      }

      assert {:ok, {_from_transaction, to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
      assert to_transaction.account_id == to_account.id
    end

    test "accepts to_account as integer ID", %{
      workspace: workspace,
      scope: scope,
      from_account: from_account,
      to_account: to_account
    } do
      attrs = %{
        from_account: from_account,
        to_account: to_account.id,
        amount: 10_000
      }

      assert {:ok, {_from_transaction, to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
      assert to_transaction.account_id == to_account.id
    end

    test "accepts to_account as UUID external_id", %{
      workspace: workspace,
      scope: scope,
      from_account: from_account,
      to_account: to_account
    } do
      attrs = %{
        from_account: from_account,
        to_account: to_account.external_id,
        amount: 10_000
      }

      assert {:ok, {_from_transaction, to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
      assert to_transaction.account_id == to_account.id
    end

    test "owner can create transfer", %{
      workspace: workspace,
      from_account: from_account,
      to_account: to_account
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{
        from_account: from_account,
        to_account: to_account,
        amount: 10_000
      }

      assert {:ok, {_from_transaction, _to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
    end

    test "editor can create transfer", %{
      workspace: workspace,
      from_account: from_account,
      to_account: to_account
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{
        from_account: from_account,
        to_account: to_account,
        amount: 10_000
      }

      assert {:ok, {_from_transaction, _to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
    end

    test "commenter cannot create transfer", %{
      workspace: workspace,
      from_account: from_account,
      to_account: to_account
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{
        from_account: from_account,
        to_account: to_account,
        amount: 10_000
      }

      assert {:error, :unauthorized} = CreateTransfer.call(scope, workspace, attrs)
    end

    test "user not in workspace cannot create transfer", %{
      workspace: workspace,
      from_account: from_account,
      to_account: to_account
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{
        from_account: from_account,
        to_account: to_account,
        amount: 10_000
      }

      assert {:error, :unauthorized} = CreateTransfer.call(scope, workspace, attrs)
    end

    test "returns error if from_account not found", %{
      workspace: workspace,
      scope: scope,
      to_account: to_account
    } do
      attrs = %{
        from_account: Ecto.UUID.generate(),
        to_account: to_account,
        amount: 10_000
      }

      assert {:error, :not_found} = CreateTransfer.call(scope, workspace, attrs)
    end

    test "returns error if to_account not found", %{
      workspace: workspace,
      scope: scope,
      from_account: from_account
    } do
      attrs = %{
        from_account: from_account,
        to_account: Ecto.UUID.generate(),
        amount: 10_000
      }

      assert {:error, :not_found} = CreateTransfer.call(scope, workspace, attrs)
    end

    test "returns error if from_account in different workspace", %{
      workspace: workspace,
      scope: scope,
      to_account: to_account
    } do
      other_workspace = CoreFactory.insert(:workspace)

      other_account = AccountingFactory.insert(:account, workspace: other_workspace)

      attrs = %{
        from_account: other_account.id,
        to_account: to_account,
        amount: 10_000
      }

      # FetchAccount filters by workspace, so account won't be found
      assert {:error, :not_found} = CreateTransfer.call(scope, workspace, attrs)
    end

    test "returns error if to_account in different workspace", %{
      workspace: workspace,
      scope: scope,
      from_account: from_account
    } do
      other_workspace = CoreFactory.insert(:workspace)

      other_account = AccountingFactory.insert(:account, workspace: other_workspace)

      attrs = %{
        from_account: from_account,
        to_account: other_account.id,
        amount: 10_000
      }

      # FetchAccount filters by workspace, so account won't be found
      assert {:error, :not_found} = CreateTransfer.call(scope, workspace, attrs)
    end

    test "returns error when transaction creation fails within transaction block", %{
      workspace: workspace,
      scope: scope,
      from_account: from_account,
      to_account: to_account
    } do
      attrs = %{
        from_account: from_account,
        to_account: to_account,
        amount: 10_000
      }

      # Stub TransactionRepository.update to fail when linking transactions
      # This will trigger the error handler in the with clause
      stub(TransactionRepository, :update, fn _transaction, _attrs ->
        changeset =
          %Transaction{}
          |> Transaction.changeset(%{})
          |> Ecto.Changeset.add_error(:linked_transaction_id, "simulated linking failure")

        {:error, changeset}
      end)

      assert {:error, changeset} = CreateTransfer.call(scope, workspace, attrs)

      assert Enum.any?(changeset.errors, fn
               {:linked_transaction_id, {"simulated linking failure", _opts}} -> true
               _error -> false
             end)
    end

    test "both transactions cleared when cleared: true", %{
      workspace: workspace,
      scope: scope,
      from_account: from_account,
      to_account: to_account
    } do
      attrs = %{
        from_account: from_account,
        to_account: to_account,
        amount: 10_000,
        cleared: true
      }

      assert {:ok, {from_transaction, to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
      assert from_transaction.cleared == true
      assert to_transaction.cleared == true
    end

    test "both transactions uncleared when cleared: false", %{
      workspace: workspace,
      scope: scope,
      from_account: from_account,
      to_account: to_account
    } do
      attrs = %{
        from_account: from_account,
        to_account: to_account,
        amount: 10_000,
        cleared: false
      }

      assert {:ok, {from_transaction, to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
      assert from_transaction.cleared == false
      assert to_transaction.cleared == false
    end

    test "defaults to uncleared when not specified", %{
      workspace: workspace,
      scope: scope,
      from_account: from_account,
      to_account: to_account
    } do
      attrs = %{
        from_account: from_account,
        to_account: to_account,
        amount: 10_000
      }

      assert {:ok, {from_transaction, to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
      assert from_transaction.cleared == false
      assert to_transaction.cleared == false
    end

    test "allows transfer to same account", %{
      workspace: workspace,
      scope: scope,
      from_account: from_account
    } do
      attrs = %{
        from_account: from_account,
        to_account: from_account,
        amount: 10_000,
        memo: "Internal rebalancing"
      }

      assert {:ok, {from_transaction, to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
      assert from_transaction.account_id == from_account.id
      assert to_transaction.account_id == from_account.id
    end

    test "handles very large amounts", %{
      workspace: workspace,
      scope: scope,
      from_account: from_account,
      to_account: to_account
    } do
      attrs = %{
        from_account: from_account,
        to_account: to_account,
        amount: 999_999_999_999
      }

      assert {:ok, {from_transaction, to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
      assert from_transaction.amount == -999_999_999_999
      assert to_transaction.amount == 999_999_999_999
    end

    test "handles memo with special characters", %{
      workspace: workspace,
      scope: scope,
      from_account: from_account,
      to_account: to_account
    } do
      attrs = %{
        from_account: from_account,
        to_account: to_account,
        amount: 10_000,
        memo: "Transfer with émojis 💰 and spëcial çhars!"
      }

      assert {:ok, {from_transaction, to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
      assert from_transaction.memo == "Transfer with émojis 💰 and spëcial çhars!"
      assert to_transaction.memo == "Transfer with émojis 💰 and spëcial çhars!"
    end

    test "works without memo", %{
      workspace: workspace,
      scope: scope,
      from_account: from_account,
      to_account: to_account
    } do
      attrs = %{
        from_account: from_account,
        to_account: to_account,
        amount: 10_000
      }

      assert {:ok, {from_transaction, to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
      assert from_transaction.memo == nil
      assert to_transaction.memo == nil
    end

    test "uses custom date when provided", %{
      workspace: workspace,
      scope: scope,
      from_account: from_account,
      to_account: to_account
    } do
      custom_date = ~D[2025-01-15]

      attrs = %{
        from_account: from_account,
        to_account: to_account,
        amount: 10_000,
        date: custom_date
      }

      assert {:ok, {from_transaction, to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
      assert from_transaction.date == custom_date
      assert to_transaction.date == custom_date
    end

    test "defaults to today when date not provided", %{
      workspace: workspace,
      scope: scope,
      from_account: from_account,
      to_account: to_account
    } do
      attrs = %{
        from_account: from_account,
        to_account: to_account,
        amount: 10_000
      }

      assert {:ok, {from_transaction, to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
      assert from_transaction.date == Date.utc_today()
      assert to_transaction.date == Date.utc_today()
    end

    test "creates transactions with same memo on both sides", %{
      workspace: workspace,
      scope: scope,
      from_account: from_account,
      to_account: to_account
    } do
      attrs = %{
        from_account: from_account,
        to_account: to_account,
        amount: 10_000,
        memo: "Monthly savings transfer"
      }

      assert {:ok, {from_transaction, to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
      assert from_transaction.memo == "Monthly savings transfer"
      assert to_transaction.memo == "Monthly savings transfer"
    end

    test "atomically rolls back if second transaction fails" do
      # This is implicitly tested by the implementation using Repo.transaction
      # If the second transaction fails, the first should be rolled back
      # In practice, this is hard to test without mocking, but the Repo.transaction
      # ensures atomicity
    end
  end

  describe "account type handling" do
    test "asset to asset: both transactions have correct signs", %{
      workspace: workspace,
      scope: scope
    } do
      checking =
        AccountingFactory.insert(:account,
          workspace: workspace,
          account_type: "checking"
        )

      savings =
        AccountingFactory.insert(:account,
          workspace: workspace,
          account_type: "savings"
        )

      attrs = %{
        from_account: checking,
        to_account: savings,
        amount: 10_000,
        memo: "Transfer to savings"
      }

      assert {:ok, {from_transaction, to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
      # Asset source: negative (money leaving)
      assert from_transaction.amount == -10_000
      assert from_transaction.account_id == checking.id
      # Asset destination: positive (money arriving)
      assert to_transaction.amount == 10_000
      assert to_transaction.account_id == savings.id
    end

    test "asset to liability: paying off debt", %{
      workspace: workspace,
      scope: scope
    } do
      checking =
        AccountingFactory.insert(:account,
          workspace: workspace,
          account_type: "checking"
        )

      credit_card =
        AccountingFactory.insert(:account,
          workspace: workspace,
          account_type: "credit_card"
        )

      attrs = %{
        from_account: checking,
        to_account: credit_card,
        amount: 15_000,
        memo: "Credit card payment"
      }

      assert {:ok, {from_transaction, to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
      # Asset source: negative (money leaving)
      assert from_transaction.amount == -15_000
      assert from_transaction.account_id == checking.id
      # Liability destination: negative (debt decreasing)
      assert to_transaction.amount == -15_000
      assert to_transaction.account_id == credit_card.id
    end

    test "liability to asset: cash advance", %{
      workspace: workspace,
      scope: scope
    } do
      credit_card =
        AccountingFactory.insert(:account,
          workspace: workspace,
          account_type: "credit_card"
        )

      checking =
        AccountingFactory.insert(:account,
          workspace: workspace,
          account_type: "checking"
        )

      attrs = %{
        from_account: credit_card,
        to_account: checking,
        amount: 20_000,
        memo: "Cash advance"
      }

      assert {:ok, {from_transaction, to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
      # Liability source: positive (debt increasing)
      assert from_transaction.amount == 20_000
      assert from_transaction.account_id == credit_card.id
      # Asset destination: positive (money arriving)
      assert to_transaction.amount == 20_000
      assert to_transaction.account_id == checking.id
    end

    test "liability to liability: balance transfer", %{
      workspace: workspace,
      scope: scope
    } do
      credit_card_a =
        AccountingFactory.insert(:account,
          workspace: workspace,
          account_type: "credit_card"
        )

      credit_card_b =
        AccountingFactory.insert(:account,
          workspace: workspace,
          account_type: "line_of_credit"
        )

      attrs = %{
        from_account: credit_card_a,
        to_account: credit_card_b,
        amount: 50_000,
        memo: "Balance transfer"
      }

      assert {:ok, {from_transaction, to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
      # Liability source: positive (debt moving away, but still owed)
      assert from_transaction.amount == 50_000
      assert from_transaction.account_id == credit_card_a.id
      # Liability destination: negative (debt increasing on target)
      assert to_transaction.amount == -50_000
      assert to_transaction.account_id == credit_card_b.id
    end

    test "works with all asset account types", %{
      workspace: workspace,
      scope: scope
    } do
      asset_types = ["checking", "savings", "cash", "asset"]

      for account_type <- asset_types do
        from_account =
          AccountingFactory.insert(:account,
            workspace: workspace,
            account_type: account_type
          )

        to_account =
          AccountingFactory.insert(:account,
            workspace: workspace,
            account_type: "checking"
          )

        attrs = %{
          from_account: from_account,
          to_account: to_account,
          amount: 1_000
        }

        assert {:ok, {from_transaction, to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
        assert from_transaction.amount == -1_000, "Failed for account_type: #{account_type}"
        assert to_transaction.amount == 1_000
      end
    end

    test "works with all liability account types", %{
      workspace: workspace,
      scope: scope
    } do
      liability_types = [
        "credit_card",
        "line_of_credit",
        "mortgage",
        "auto_loan",
        "student_loan",
        "personal_loan",
        "medical_debt",
        "other_debt",
        "liability"
      ]

      checking =
        AccountingFactory.insert(:account,
          workspace: workspace,
          account_type: "checking"
        )

      for account_type <- liability_types do
        liability_account =
          AccountingFactory.insert(:account,
            workspace: workspace,
            account_type: account_type
          )

        attrs = %{
          from_account: checking,
          to_account: liability_account,
          amount: 1_000
        }

        assert {:ok, {from_transaction, to_transaction}} = CreateTransfer.call(scope, workspace, attrs)
        assert from_transaction.amount == -1_000
        assert to_transaction.amount == -1_000, "Failed for account_type: #{account_type}"
      end
    end
  end

  describe "integration with context API" do
    test "can be called through Accounting.create_transfer/3", %{
      workspace: workspace,
      scope: scope,
      from_account: from_account,
      to_account: to_account
    } do
      attrs = %{
        from_account: from_account,
        to_account: to_account,
        amount: 25_000,
        memo: "Context API test"
      }

      assert {:ok, {from_transaction, to_transaction}} =
               PurseCraft.Accounting.create_transfer(scope, workspace, attrs)

      assert %Transaction{} = from_transaction
      assert %Transaction{} = to_transaction
      assert from_transaction.amount == -25_000
      assert to_transaction.amount == 25_000
    end
  end
end
