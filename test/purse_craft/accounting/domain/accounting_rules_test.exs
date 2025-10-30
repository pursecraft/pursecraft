defmodule PurseCraft.Accounting.Domain.AccountingRulesTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Accounting.Domain.AccountingRules
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Accounting.Schemas.Transaction

  describe "asset_account?/1" do
    test "returns true for checking account" do
      account = %Account{account_type: "checking"}
      assert AccountingRules.asset_account?(account)
    end

    test "returns true for savings account" do
      account = %Account{account_type: "savings"}
      assert AccountingRules.asset_account?(account)
    end

    test "returns true for cash account" do
      account = %Account{account_type: "cash"}
      assert AccountingRules.asset_account?(account)
    end

    test "returns true for generic asset account" do
      account = %Account{account_type: "asset"}
      assert AccountingRules.asset_account?(account)
    end

    test "returns false for credit card account" do
      account = %Account{account_type: "credit_card"}
      refute AccountingRules.asset_account?(account)
    end

    test "returns false for loan account" do
      account = %Account{account_type: "auto_loan"}
      refute AccountingRules.asset_account?(account)
    end
  end

  describe "liability_account?/1" do
    test "returns true for credit card account" do
      account = %Account{account_type: "credit_card"}
      assert AccountingRules.liability_account?(account)
    end

    test "returns true for line of credit" do
      account = %Account{account_type: "line_of_credit"}
      assert AccountingRules.liability_account?(account)
    end

    test "returns true for mortgage" do
      account = %Account{account_type: "mortgage"}
      assert AccountingRules.liability_account?(account)
    end

    test "returns true for auto loan" do
      account = %Account{account_type: "auto_loan"}
      assert AccountingRules.liability_account?(account)
    end

    test "returns true for student loan" do
      account = %Account{account_type: "student_loan"}
      assert AccountingRules.liability_account?(account)
    end

    test "returns true for personal loan" do
      account = %Account{account_type: "personal_loan"}
      assert AccountingRules.liability_account?(account)
    end

    test "returns true for medical debt" do
      account = %Account{account_type: "medical_debt"}
      assert AccountingRules.liability_account?(account)
    end

    test "returns true for other debt" do
      account = %Account{account_type: "other_debt"}
      assert AccountingRules.liability_account?(account)
    end

    test "returns true for generic liability account" do
      account = %Account{account_type: "liability"}
      assert AccountingRules.liability_account?(account)
    end

    test "returns false for checking account" do
      account = %Account{account_type: "checking"}
      refute AccountingRules.liability_account?(account)
    end

    test "returns false for savings account" do
      account = %Account{account_type: "savings"}
      refute AccountingRules.liability_account?(account)
    end
  end

  describe "transfer_amount/3 with :source direction" do
    test "asset account source has negative amount" do
      checking = %Account{account_type: "checking"}
      assert AccountingRules.transfer_amount(checking, 10_000, :source) == -10_000
    end

    test "savings account source has negative amount" do
      savings = %Account{account_type: "savings"}
      assert AccountingRules.transfer_amount(savings, 5_000, :source) == -5_000
    end

    test "cash account source has negative amount" do
      cash = %Account{account_type: "cash"}
      assert AccountingRules.transfer_amount(cash, 2_000, :source) == -2_000
    end

    test "generic asset account source has negative amount" do
      asset = %Account{account_type: "asset"}
      assert AccountingRules.transfer_amount(asset, 15_000, :source) == -15_000
    end

    test "credit card source has positive amount" do
      credit_card = %Account{account_type: "credit_card"}
      assert AccountingRules.transfer_amount(credit_card, 10_000, :source) == 10_000
    end

    test "line of credit source has positive amount" do
      loc = %Account{account_type: "line_of_credit"}
      assert AccountingRules.transfer_amount(loc, 20_000, :source) == 20_000
    end

    test "mortgage source has positive amount" do
      mortgage = %Account{account_type: "mortgage"}
      assert AccountingRules.transfer_amount(mortgage, 100_000, :source) == 100_000
    end

    test "auto loan source has positive amount" do
      auto_loan = %Account{account_type: "auto_loan"}
      assert AccountingRules.transfer_amount(auto_loan, 5_000, :source) == 5_000
    end

    test "student loan source has positive amount" do
      student_loan = %Account{account_type: "student_loan"}
      assert AccountingRules.transfer_amount(student_loan, 10_000, :source) == 10_000
    end

    test "personal loan source has positive amount" do
      personal_loan = %Account{account_type: "personal_loan"}
      assert AccountingRules.transfer_amount(personal_loan, 3_000, :source) == 3_000
    end

    test "medical debt source has positive amount" do
      medical_debt = %Account{account_type: "medical_debt"}
      assert AccountingRules.transfer_amount(medical_debt, 8_000, :source) == 8_000
    end

    test "other debt source has positive amount" do
      other_debt = %Account{account_type: "other_debt"}
      assert AccountingRules.transfer_amount(other_debt, 1_000, :source) == 1_000
    end

    test "generic liability source has positive amount" do
      liability = %Account{account_type: "liability"}
      assert AccountingRules.transfer_amount(liability, 7_000, :source) == 7_000
    end
  end

  describe "transfer_amount/3 with :destination direction" do
    test "asset account destination has positive amount" do
      checking = %Account{account_type: "checking"}
      assert AccountingRules.transfer_amount(checking, 10_000, :destination) == 10_000
    end

    test "savings account destination has positive amount" do
      savings = %Account{account_type: "savings"}
      assert AccountingRules.transfer_amount(savings, 5_000, :destination) == 5_000
    end

    test "cash account destination has positive amount" do
      cash = %Account{account_type: "cash"}
      assert AccountingRules.transfer_amount(cash, 2_000, :destination) == 2_000
    end

    test "generic asset account destination has positive amount" do
      asset = %Account{account_type: "asset"}
      assert AccountingRules.transfer_amount(asset, 15_000, :destination) == 15_000
    end

    test "credit card destination has negative amount" do
      credit_card = %Account{account_type: "credit_card"}
      assert AccountingRules.transfer_amount(credit_card, 10_000, :destination) == -10_000
    end

    test "line of credit destination has negative amount" do
      loc = %Account{account_type: "line_of_credit"}
      assert AccountingRules.transfer_amount(loc, 20_000, :destination) == -20_000
    end

    test "mortgage destination has negative amount" do
      mortgage = %Account{account_type: "mortgage"}
      assert AccountingRules.transfer_amount(mortgage, 100_000, :destination) == -100_000
    end

    test "auto loan destination has negative amount" do
      auto_loan = %Account{account_type: "auto_loan"}
      assert AccountingRules.transfer_amount(auto_loan, 5_000, :destination) == -5_000
    end

    test "student loan destination has negative amount" do
      student_loan = %Account{account_type: "student_loan"}
      assert AccountingRules.transfer_amount(student_loan, 10_000, :destination) == -10_000
    end

    test "personal loan destination has negative amount" do
      personal_loan = %Account{account_type: "personal_loan"}
      assert AccountingRules.transfer_amount(personal_loan, 3_000, :destination) == -3_000
    end

    test "medical debt destination has negative amount" do
      medical_debt = %Account{account_type: "medical_debt"}
      assert AccountingRules.transfer_amount(medical_debt, 8_000, :destination) == -8_000
    end

    test "other debt destination has negative amount" do
      other_debt = %Account{account_type: "other_debt"}
      assert AccountingRules.transfer_amount(other_debt, 1_000, :destination) == -1_000
    end

    test "generic liability destination has negative amount" do
      liability = %Account{account_type: "liability"}
      assert AccountingRules.transfer_amount(liability, 7_000, :destination) == -7_000
    end
  end

  describe "transfer_amount/3 scenario tests" do
    test "asset to asset transfer: checking to savings" do
      checking = %Account{account_type: "checking"}
      savings = %Account{account_type: "savings"}
      amount = 50_000

      assert AccountingRules.transfer_amount(checking, amount, :source) == -50_000
      assert AccountingRules.transfer_amount(savings, amount, :destination) == 50_000
    end

    test "asset to liability transfer: checking to credit card (paying off debt)" do
      checking = %Account{account_type: "checking"}
      credit_card = %Account{account_type: "credit_card"}
      amount = 15_000

      assert AccountingRules.transfer_amount(checking, amount, :source) == -15_000
      assert AccountingRules.transfer_amount(credit_card, amount, :destination) == -15_000
    end

    test "liability to asset transfer: credit card to checking (cash advance)" do
      credit_card = %Account{account_type: "credit_card"}
      checking = %Account{account_type: "checking"}
      amount = 20_000

      assert AccountingRules.transfer_amount(credit_card, amount, :source) == 20_000
      assert AccountingRules.transfer_amount(checking, amount, :destination) == 20_000
    end

    test "liability to liability transfer: credit card to line of credit (balance transfer)" do
      credit_card = %Account{account_type: "credit_card"}
      line_of_credit = %Account{account_type: "line_of_credit"}
      amount = 100_000

      assert AccountingRules.transfer_amount(credit_card, amount, :source) == 100_000
      assert AccountingRules.transfer_amount(line_of_credit, amount, :destination) == -100_000
    end
  end

  describe "infer_transfer_direction/1" do
    test "asset with negative amount is :source" do
      checking = %Account{account_type: "checking"}
      transaction = %Transaction{account: checking, amount: -10_000}

      assert AccountingRules.infer_transfer_direction(transaction) == :source
    end

    test "asset with positive amount is :destination" do
      savings = %Account{account_type: "savings"}
      transaction = %Transaction{account: savings, amount: 5_000}

      assert AccountingRules.infer_transfer_direction(transaction) == :destination
    end

    test "asset with zero amount is :destination" do
      checking = %Account{account_type: "checking"}
      transaction = %Transaction{account: checking, amount: 0}

      assert AccountingRules.infer_transfer_direction(transaction) == :destination
    end

    test "liability with positive amount is :source" do
      credit_card = %Account{account_type: "credit_card"}
      transaction = %Transaction{account: credit_card, amount: 10_000}

      assert AccountingRules.infer_transfer_direction(transaction) == :source
    end

    test "liability with negative amount is :destination" do
      line_of_credit = %Account{account_type: "line_of_credit"}
      transaction = %Transaction{account: line_of_credit, amount: -15_000}

      assert AccountingRules.infer_transfer_direction(transaction) == :destination
    end

    test "liability with zero amount is :destination" do
      credit_card = %Account{account_type: "credit_card"}
      transaction = %Transaction{account: credit_card, amount: 0}

      assert AccountingRules.infer_transfer_direction(transaction) == :destination
    end

    test "checking account source (negative amount)" do
      checking = %Account{account_type: "checking"}
      transaction = %Transaction{account: checking, amount: -50_000}

      assert AccountingRules.infer_transfer_direction(transaction) == :source
    end

    test "checking account destination (positive amount)" do
      checking = %Account{account_type: "checking"}
      transaction = %Transaction{account: checking, amount: 50_000}

      assert AccountingRules.infer_transfer_direction(transaction) == :destination
    end

    test "cash account source (negative amount)" do
      cash = %Account{account_type: "cash"}
      transaction = %Transaction{account: cash, amount: -1_000}

      assert AccountingRules.infer_transfer_direction(transaction) == :source
    end

    test "mortgage source (positive amount)" do
      mortgage = %Account{account_type: "mortgage"}
      transaction = %Transaction{account: mortgage, amount: 100_000}

      assert AccountingRules.infer_transfer_direction(transaction) == :source
    end

    test "mortgage destination (negative amount)" do
      mortgage = %Account{account_type: "mortgage"}
      transaction = %Transaction{account: mortgage, amount: -100_000}

      assert AccountingRules.infer_transfer_direction(transaction) == :destination
    end

    test "auto loan source (positive amount)" do
      auto_loan = %Account{account_type: "auto_loan"}
      transaction = %Transaction{account: auto_loan, amount: 5_000}

      assert AccountingRules.infer_transfer_direction(transaction) == :source
    end

    test "student loan destination (negative amount)" do
      student_loan = %Account{account_type: "student_loan"}
      transaction = %Transaction{account: student_loan, amount: -10_000}

      assert AccountingRules.infer_transfer_direction(transaction) == :destination
    end
  end

  describe "infer_transfer_direction/1 scenario tests" do
    test "asset to asset: checking (source) to savings (destination)" do
      checking = %Account{account_type: "checking"}
      savings = %Account{account_type: "savings"}

      from_transaction = %Transaction{account: checking, amount: -10_000}
      to_transaction = %Transaction{account: savings, amount: 10_000}

      assert AccountingRules.infer_transfer_direction(from_transaction) == :source
      assert AccountingRules.infer_transfer_direction(to_transaction) == :destination
    end

    test "asset to liability: checking (source) to credit card (destination)" do
      checking = %Account{account_type: "checking"}
      credit_card = %Account{account_type: "credit_card"}

      from_transaction = %Transaction{account: checking, amount: -15_000}
      to_transaction = %Transaction{account: credit_card, amount: -15_000}

      assert AccountingRules.infer_transfer_direction(from_transaction) == :source
      assert AccountingRules.infer_transfer_direction(to_transaction) == :destination
    end

    test "liability to asset: credit card (source) to checking (destination)" do
      credit_card = %Account{account_type: "credit_card"}
      checking = %Account{account_type: "checking"}

      from_transaction = %Transaction{account: credit_card, amount: 20_000}
      to_transaction = %Transaction{account: checking, amount: 20_000}

      assert AccountingRules.infer_transfer_direction(from_transaction) == :source
      assert AccountingRules.infer_transfer_direction(to_transaction) == :destination
    end

    test "liability to liability: credit card (source) to line of credit (destination)" do
      credit_card = %Account{account_type: "credit_card"}
      line_of_credit = %Account{account_type: "line_of_credit"}

      from_transaction = %Transaction{account: credit_card, amount: 50_000}
      to_transaction = %Transaction{account: line_of_credit, amount: -50_000}

      assert AccountingRules.infer_transfer_direction(from_transaction) == :source
      assert AccountingRules.infer_transfer_direction(to_transaction) == :destination
    end
  end
end
