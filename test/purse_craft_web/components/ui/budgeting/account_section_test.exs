defmodule PurseCraftWeb.Components.UI.Budgeting.AccountSectionTest do
  use PurseCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias PurseCraftWeb.Components.UI.Budgeting.AccountSection

  describe "account_section/1" do
    test "renders section title and total" do
      assigns = %{
        id: "budget-accounts",
        title: "BUDGET ACCOUNTS",
        accounts: [],
        current_path: "/books/test-book/budget",
        total: "$1,234.56"
      }

      result = render_component(&AccountSection.account_section/1, assigns)

      assert result =~ "BUDGET ACCOUNTS"
      assert result =~ "$1,234.56"
    end

    test "displays empty state when no accounts exist" do
      assigns = %{
        id: "budget-accounts",
        title: "BUDGET ACCOUNTS",
        accounts: [],
        current_path: "/books/test-book/budget",
        total: "$0.00"
      }

      result = render_component(&AccountSection.account_section/1, assigns)

      assert result =~ "No accounts yet"
    end

    test "renders accounts with names and icons" do
      accounts = [
        %{
          name: "Checking Account",
          account_type: "checking",
          external_id: "checking-123",
          closed_at: nil
        },
        %{
          name: "Savings Account",
          account_type: "savings",
          external_id: "savings-456",
          closed_at: nil
        }
      ]

      assigns = %{
        id: "budget-accounts",
        title: "BUDGET ACCOUNTS",
        accounts: accounts,
        current_path: "/books/test-book/budget",
        total: "$5,000.00"
      }

      result = render_component(&AccountSection.account_section/1, assigns)

      assert result =~ "Checking Account"
      assert result =~ "Savings Account"
    end

    test "generates correct account links" do
      accounts = [
        %{
          name: "Test Account",
          account_type: "checking",
          external_id: "test-account-123",
          closed_at: nil
        }
      ]

      assigns = %{
        id: "budget-accounts",
        title: "BUDGET ACCOUNTS",
        accounts: accounts,
        current_path: "/books/test-book-456/budget",
        total: "$1,000.00"
      }

      result = render_component(&AccountSection.account_section/1, assigns)

      assert result =~ "/books/test-book-456/accounts/test-account-123"
    end

    test "shows placeholder balance for accounts" do
      accounts = [
        %{
          name: "Test Account",
          account_type: "checking",
          external_id: "test-account-123",
          closed_at: nil
        }
      ]

      assigns = %{
        id: "budget-accounts",
        title: "BUDGET ACCOUNTS",
        accounts: accounts,
        current_path: "/books/test-book/budget",
        total: "$1,000.00"
      }

      result = render_component(&AccountSection.account_section/1, assigns)

      assert result =~ "$0.00"
    end
  end

  describe "group_accounts_by_type/1" do
    test "groups cash accounts correctly" do
      accounts = [
        %{account_type: "checking", closed_at: nil},
        %{account_type: "savings", closed_at: nil},
        %{account_type: "cash", closed_at: nil}
      ]

      result = AccountSection.group_accounts_by_type(accounts)

      assert Enum.count(result.cash) == 3
      assert result.credit == []
      assert result.loans == []
      assert result.tracking == []
    end

    test "groups credit accounts correctly" do
      accounts = [
        %{account_type: "credit_card", closed_at: nil},
        %{account_type: "line_of_credit", closed_at: nil}
      ]

      result = AccountSection.group_accounts_by_type(accounts)

      assert result.cash == []
      assert Enum.count(result.credit) == 2
      assert result.loans == []
      assert result.tracking == []
    end

    test "groups loan accounts correctly" do
      accounts = [
        %{account_type: "mortgage", closed_at: nil},
        %{account_type: "auto_loan", closed_at: nil},
        %{account_type: "student_loan", closed_at: nil}
      ]

      result = AccountSection.group_accounts_by_type(accounts)

      assert result.cash == []
      assert result.credit == []
      assert Enum.count(result.loans) == 3
      assert result.tracking == []
    end

    test "groups tracking accounts correctly" do
      accounts = [
        %{account_type: "asset", closed_at: nil},
        %{account_type: "liability", closed_at: nil}
      ]

      result = AccountSection.group_accounts_by_type(accounts)

      assert result.cash == []
      assert result.credit == []
      assert result.loans == []
      assert Enum.count(result.tracking) == 2
    end

    test "filters out closed accounts" do
      accounts = [
        %{account_type: "checking", closed_at: nil},
        %{account_type: "savings", closed_at: ~U[2024-01-01 00:00:00Z]},
        %{account_type: "asset", closed_at: nil},
        %{account_type: "liability", closed_at: ~U[2024-01-01 00:00:00Z]}
      ]

      result = AccountSection.group_accounts_by_type(accounts)

      assert Enum.count(result.cash) == 1
      assert result.credit == []
      assert result.loans == []
      assert Enum.count(result.tracking) == 1
    end

    test "returns empty lists when no accounts provided" do
      result = AccountSection.group_accounts_by_type([])

      assert result.cash == []
      assert result.credit == []
      assert result.loans == []
      assert result.tracking == []
    end

    test "handles mixed account types" do
      accounts = [
        %{account_type: "checking", closed_at: nil},
        %{account_type: "asset", closed_at: nil},
        %{account_type: "credit_card", closed_at: nil},
        %{account_type: "mortgage", closed_at: nil}
      ]

      result = AccountSection.group_accounts_by_type(accounts)

      assert Enum.count(result.cash) == 1
      assert Enum.count(result.credit) == 1
      assert Enum.count(result.loans) == 1
      assert Enum.count(result.tracking) == 1
    end
  end
end
