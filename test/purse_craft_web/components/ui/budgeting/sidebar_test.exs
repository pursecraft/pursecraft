defmodule PurseCraftWeb.Components.UI.Budgeting.SidebarTest do
  use PurseCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias PurseCraftWeb.Components.UI.Budgeting.Sidebar

  setup do
    user = PurseCraft.IdentityFactory.build(:user, email: "test@example.com")
    scope = PurseCraft.IdentityFactory.build(:scope, user: user)
    book = PurseCraft.CoreFactory.build(:book, external_id: "abcd1234-5678-90ab-cdef-1234567890ab")
    %{user: user, scope: scope, book: book}
  end

  describe "LiveComponent" do
    test "renders the sidebar with navigation links", %{scope: scope, book: book} do
      result =
        render_component(Sidebar, %{
          id: "sidebar-test",
          current_path: "/books/#{book.external_id}/budget",
          current_scope: scope
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
          current_scope: scope
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
          current_scope: scope
        })

      assert result =~ "<select"
      assert result =~ "My Budget"
      assert result =~ "Family Budget"
      assert result =~ "+ Create New Budget"
    end

    test "renders accounts lists in sidebar", %{scope: scope, book: book} do
      result =
        render_component(Sidebar, %{
          id: "sidebar-test",
          current_path: "/books/#{book.external_id}/budget",
          current_scope: scope,
          accounts: []
        })

      # When no accounts provided, no sections should appear due to :if conditions
      refute result =~ "CASH"
      refute result =~ "CREDIT"
      refute result =~ "LOANS"
      refute result =~ "TRACKING"
      refute result =~ "$0.00"

      assert result =~ "Add Account"
      assert result =~ "hero-plus-small"
    end

    test "renders actual accounts when provided", %{scope: scope, book: book} do
      accounts = [
        %{
          name: "Checking Account",
          account_type: "checking",
          external_id: "checking-123",
          closed_at: nil
        },
        %{
          name: "Investment Account",
          account_type: "asset",
          external_id: "asset-456",
          closed_at: nil
        }
      ]

      result =
        render_component(Sidebar, %{
          id: "sidebar-test",
          current_path: "/books/#{book.external_id}/budget",
          current_scope: scope,
          accounts: accounts
        })

      assert result =~ "CASH"
      assert result =~ "TRACKING"
      refute result =~ "CREDIT"
      refute result =~ "LOANS"
      assert result =~ "Checking Account"
      assert result =~ "Investment Account"
      assert result =~ "hero-chart-bar"
    end

    test "renders credit accounts when provided", %{scope: scope, book: book} do
      accounts = [
        %{
          name: "Credit Card",
          account_type: "credit_card",
          external_id: "credit-123",
          closed_at: nil
        },
        %{
          name: "Line of Credit",
          account_type: "line_of_credit",
          external_id: "loc-456",
          closed_at: nil
        }
      ]

      result =
        render_component(Sidebar, %{
          id: "sidebar-test",
          current_path: "/books/#{book.external_id}/budget",
          current_scope: scope,
          accounts: accounts
        })

      assert result =~ "CREDIT"
      refute result =~ "CASH"
      refute result =~ "LOANS"
      refute result =~ "TRACKING"
      assert result =~ "Credit Card"
      assert result =~ "Line of Credit"
    end

    test "renders loan accounts when provided", %{scope: scope, book: book} do
      accounts = [
        %{
          name: "Mortgage",
          account_type: "mortgage",
          external_id: "mortgage-123",
          closed_at: nil
        },
        %{
          name: "Auto Loan",
          account_type: "auto_loan",
          external_id: "auto-456",
          closed_at: nil
        }
      ]

      result =
        render_component(Sidebar, %{
          id: "sidebar-test",
          current_path: "/books/#{book.external_id}/budget",
          current_scope: scope,
          accounts: accounts
        })

      assert result =~ "LOANS"
      refute result =~ "CASH"
      refute result =~ "CREDIT"
      refute result =~ "TRACKING"
      assert result =~ "Mortgage"
      assert result =~ "Auto Loan"
    end

    test "handles logout link", %{scope: scope, book: book} do
      result =
        render_component(Sidebar, %{
          id: "sidebar-test",
          current_path: "/books/#{book.external_id}/budget",
          current_scope: scope
        })

      assert result =~ ~r/<a[^>]*href="\/users\/log-out"/
      assert result =~ "hero-arrow-right-on-rectangle"
    end

    test "renders user initial in avatar", %{scope: scope, book: book} do
      result =
        render_component(Sidebar, %{
          id: "sidebar-test",
          current_path: "/books/#{book.external_id}/budget",
          current_scope: scope
        })

      assert result =~ "T"
      assert result =~ "avatar"
    end

    test "renders sidebar with hidden mobile class by default", %{scope: scope, book: book} do
      result =
        render_component(Sidebar, %{
          id: "sidebar-test",
          current_path: "/books/#{book.external_id}/budget",
          current_scope: scope
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
