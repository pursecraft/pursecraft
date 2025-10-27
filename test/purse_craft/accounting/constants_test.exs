defmodule PurseCraft.Accounting.ConstantsTest do
  use ExUnit.Case, async: true

  alias PurseCraft.Accounting.Constants

  describe "asset_account_types/0" do
    test "returns list of asset account types" do
      types = Constants.asset_account_types()
      assert is_list(types)
      assert "checking" in types
      assert "savings" in types
      assert "cash" in types
      assert "asset" in types
      assert length(types) == 4
    end

    test "does not include liability types" do
      asset_types = Constants.asset_account_types()
      refute "credit_card" in asset_types
      refute "mortgage" in asset_types
    end
  end

  describe "liability_account_types/0" do
    test "returns list of liability account types" do
      types = Constants.liability_account_types()
      assert is_list(types)
      assert "credit_card" in types
      assert "line_of_credit" in types
      assert "mortgage" in types
      assert "auto_loan" in types
      assert "student_loan" in types
      assert "personal_loan" in types
      assert "medical_debt" in types
      assert "other_debt" in types
      assert "liability" in types
      assert length(types) == 9
    end

    test "does not include asset types" do
      liability_types = Constants.liability_account_types()
      refute "checking" in liability_types
      refute "savings" in liability_types
    end
  end

  describe "all_account_types/0" do
    test "returns complete list combining assets and liabilities" do
      types = Constants.all_account_types()
      assert is_list(types)
      assert length(types) == 13
    end

    test "includes all asset types" do
      all_types = Constants.all_account_types()
      assert "checking" in all_types
      assert "savings" in all_types
      assert "cash" in all_types
      assert "asset" in all_types
    end

    test "includes all liability types" do
      all_types = Constants.all_account_types()
      assert "credit_card" in all_types
      assert "line_of_credit" in all_types
      assert "mortgage" in all_types
      assert "auto_loan" in all_types
      assert "student_loan" in all_types
      assert "personal_loan" in all_types
      assert "medical_debt" in all_types
      assert "other_debt" in all_types
      assert "liability" in all_types
    end

    test "has no duplicates" do
      all_types = Constants.all_account_types()
      unique_types = Enum.uniq(all_types)
      assert length(all_types) == length(unique_types)
    end

    test "equals asset types plus liability types" do
      all_types = Constants.all_account_types()
      asset_types = Constants.asset_account_types()
      liability_types = Constants.liability_account_types()

      assert Enum.sort(all_types) == Enum.sort(asset_types ++ liability_types)
    end
  end
end
