defmodule PurseCraft.Search.Commands.Fields.EnrichSearchFieldsTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.AccountingFactory
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.Search.Commands.Fields.EnrichSearchFields

  setup do
    workspace = CoreFactory.insert(:workspace)
    account = AccountingFactory.insert(:account, workspace: workspace, name: "Chase Checking")
    payee = AccountingFactory.insert(:payee, workspace: workspace, name: "Kroger Store")

    category = BudgetingFactory.insert(:category, workspace: workspace)
    envelope = BudgetingFactory.insert(:envelope, category: category, name: "Groceries")

    {:ok, workspace: workspace, account: account, payee: payee, envelope: envelope}
  end

  describe "call/3" do
    test "enriches transaction searchable fields with all associations", %{
      workspace: workspace,
      account: account,
      payee: payee,
      envelope: envelope
    } do
      transaction =
        AccountingFactory.insert(:transaction,
          workspace: workspace,
          account: account,
          payee: payee,
          memo: "Weekly shopping"
        )

      AccountingFactory.insert(:transaction_line,
        transaction: transaction,
        envelope: envelope,
        amount: 2500
      )

      base_fields = %{"memo" => "Weekly shopping"}

      assert {:ok, enriched_fields} = EnrichSearchFields.call("transaction", transaction.id, base_fields)

      assert enriched_fields["memo"] == "Weekly shopping"
      assert enriched_fields["payee_name"] == "Kroger Store"
      assert enriched_fields["account_name"] == "Chase Checking"
      assert enriched_fields["envelope_names"] == "Groceries"
    end

    test "handles transaction with multiple envelopes", %{
      workspace: workspace,
      account: account,
      payee: payee,
      envelope: envelope
    } do
      envelope2 = BudgetingFactory.insert(:envelope, category: envelope.category, name: "Household")

      transaction =
        AccountingFactory.insert(:transaction,
          workspace: workspace,
          account: account,
          payee: payee,
          memo: "Split purchase"
        )

      AccountingFactory.insert(:transaction_line,
        transaction: transaction,
        envelope: envelope,
        amount: 3000
      )

      AccountingFactory.insert(:transaction_line,
        transaction: transaction,
        envelope: envelope2,
        amount: 2000
      )

      base_fields = %{"memo" => "Split purchase"}

      assert {:ok, enriched_fields} = EnrichSearchFields.call("transaction", transaction.id, base_fields)

      envelope_names = enriched_fields["envelope_names"]
      assert String.contains?(envelope_names, "Groceries")
      assert String.contains?(envelope_names, "Household")
    end

    test "handles transaction with line-level payee overrides", %{
      workspace: workspace,
      account: account,
      payee: payee,
      envelope: envelope
    } do
      line_payee = AccountingFactory.insert(:payee, workspace: workspace, name: "Gas Station")

      transaction =
        AccountingFactory.insert(:transaction,
          workspace: workspace,
          account: account,
          payee: payee,
          memo: "Mixed purchase"
        )

      AccountingFactory.insert(:transaction_line,
        transaction: transaction,
        envelope: envelope,
        payee: line_payee,
        amount: 2500
      )

      base_fields = %{"memo" => "Mixed purchase"}

      assert {:ok, enriched_fields} = EnrichSearchFields.call("transaction", transaction.id, base_fields)

      assert enriched_fields["payee_name"] == "Kroger Store"
      assert enriched_fields["line_payee_names"] == "Gas Station"
    end

    test "handles transaction with minimal associations", %{
      workspace: workspace,
      account: account
    } do
      transaction =
        AccountingFactory.insert(:transaction,
          workspace: workspace,
          account: account,
          payee: nil,
          memo: "Simple transaction"
        )

      base_fields = %{"memo" => "Simple transaction"}

      assert {:ok, enriched_fields} = EnrichSearchFields.call("transaction", transaction.id, base_fields)

      assert enriched_fields["memo"] == "Simple transaction"
      assert enriched_fields["account_name"] == "Chase Checking"
      assert Map.has_key?(enriched_fields, "payee_name") == false
    end

    test "returns original fields for non-transaction entity types" do
      base_fields = %{"name" => "Test Payee"}

      assert {:ok, enriched_fields} = EnrichSearchFields.call("payee", 123, base_fields)

      assert enriched_fields == base_fields
    end

    test "handles non-existent transaction gracefully" do
      base_fields = %{"memo" => "Non-existent"}

      assert {:ok, enriched_fields} = EnrichSearchFields.call("transaction", 99_999, base_fields)

      assert enriched_fields == base_fields
    end
  end
end
