defmodule PurseCraftWeb.Components.UI.Budgeting.SidebarTest do
  use PurseCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias PurseCraft.AccountingFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraftWeb.Components.UI.Budgeting.Sidebar

  setup do
    user = IdentityFactory.build(:user, email: "test@example.com")
    scope = IdentityFactory.build(:scope, user: user)
    book = IdentityFactory.build(:book, external_id: "abcd1234-5678-90ab-cdef-1234567890ab")
    %{user: user, scope: scope, book: book}
  end

  describe "LiveComponent" do
    test "renders the sidebar with navigation links", %{scope: scope, book: book} do
      result =
        render_component(Sidebar, %{
          id: "sidebar-test",
          current_path: "/books/#{book.external_id}/budget",
          current_scope: scope,
          accounts: []
        })

      assert result =~ "PurseCraft Logo"
      assert result =~ "PurseCraft"

      assert result =~ "Budget"
      assert result =~ "Reports"
      assert result =~ "All Accounts"

      assert result =~ "test@example.com"
      assert result =~ "Settings"
    end

    test "highlights the active route", %{scope: scope, book: book} do
      budget_result =
        render_component(Sidebar, %{
          id: "sidebar-test",
          current_path: "/books/#{book.external_id}/budget",
          current_scope: scope,
          accounts: []
        })

      assert budget_result =~ ~r/<a[^>]*href="\/books\/#{book.external_id}\/budget"[^>]*class="[^"]*bg-primary/

      reports_result =
        render_component(Sidebar, %{
          id: "sidebar-test",
          current_path: "/books/#{book.external_id}/reports",
          current_scope: scope
        })

      assert reports_result =~ ~r/<a[^>]*href="\/books\/#{book.external_id}\/reports"[^>]*class="[^"]*bg-primary/

      accounts_result =
        render_component(Sidebar, %{
          id: "sidebar-test",
          current_path: "/books/#{book.external_id}/accounts",
          current_scope: scope
        })

      assert accounts_result =~ ~r/<a[^>]*href="\/books\/#{book.external_id}\/accounts"[^>]*class="[^"]*bg-primary/
    end

    test "renders book selection dropdown", %{scope: scope, book: book} do
      result =
        render_component(Sidebar, %{
          id: "sidebar-test",
          current_path: "/books/#{book.external_id}/budget",
          current_scope: scope,
          accounts: []
        })

      assert result =~ "<select"
      assert result =~ "My Budget"
      assert result =~ "Family Budget"
      assert result =~ "+ Create New Budget"
    end

    test "renders accounts lists in sidebar", %{scope: scope, book: book} do
      # Create budget accounts (appear in BUDGET ACCOUNTS section)
      checking_account = AccountingFactory.build(:account, name: "Checking", account_type: "checking")
      savings_account = AccountingFactory.build(:account, name: "Savings", account_type: "savings")
      
      # Create tracking accounts (appear in TRACKING ACCOUNTS section)  
      investment = AccountingFactory.build(:account, name: "Investment", account_type: "asset")

      accounts = [checking_account, savings_account, investment]

      result =
        render_component(Sidebar, %{
          id: "sidebar-test",
          current_path: "/books/#{book.external_id}/budget",
          current_scope: scope,
          accounts: accounts
        })

      assert result =~ "BUDGET ACCOUNTS"
      assert result =~ "TRACKING ACCOUNTS"

      assert result =~ "Checking"
      assert result =~ "Savings"
      assert result =~ "Investment"

      assert result =~ "Add Account"
      assert result =~ "hero-plus-small"
    end

    test "handles logout link", %{scope: scope, book: book} do
      result =
        render_component(Sidebar, %{
          id: "sidebar-test",
          current_path: "/books/#{book.external_id}/budget",
          current_scope: scope,
          accounts: []
        })

      assert result =~ ~r/<a[^>]*href="\/users\/log-out"/
      assert result =~ "hero-arrow-right-on-rectangle"
    end

    test "renders user initial in avatar", %{scope: scope, book: book} do
      result =
        render_component(Sidebar, %{
          id: "sidebar-test",
          current_path: "/books/#{book.external_id}/budget",
          current_scope: scope,
          accounts: []
        })

      assert result =~ "T"
      assert result =~ "avatar"
    end

    test "renders sidebar with hidden mobile class by default", %{scope: scope, book: book} do
      result =
        render_component(Sidebar, %{
          id: "sidebar-test",
          current_path: "/books/#{book.external_id}/budget",
          current_scope: scope,
          accounts: []
        })

      # Verify the sidebar has the hidden class initially
      assert result =~ "id=\"sidebar-container\""
      assert result =~ "-translate-x-full lg:translate-x-0"

      # Verify burger button exists
      assert result =~ "phx-click="
      assert result =~ "<button"
      assert result =~ "hero-bars-3"
    end
  end
end
