defmodule PurseCraftWeb.Components.UI.Budgeting.SidebarTest do
  use PurseCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias PurseCraftWeb.Components.UI.Budgeting.Sidebar

  setup do
    user = PurseCraft.IdentityFactory.build(:user, email: "test@example.com")
    scope = PurseCraft.IdentityFactory.build(:scope, user: user)
    book = PurseCraft.BudgetingFactory.build(:book, external_id: "abcd1234-5678-90ab-cdef-1234567890ab")
    %{user: user, scope: scope, book: book}
  end

  describe "sidebar/1" do
    test "renders the sidebar with navigation links", %{scope: scope, book: book} do
      result =
        render_component(&Sidebar.sidebar/1, %{
          current_path: "/books/#{book.external_id}/budget",
          current_scope: scope
        })

      # Check for PurseCraft logo and name
      assert result =~ "PurseCraft Logo"
      assert result =~ "PurseCraft"

      # Check for navigation links
      assert result =~ "Budget"
      assert result =~ "Reports"
      assert result =~ "All Accounts"

      # Check for user info
      assert result =~ "test@example.com"
      assert result =~ "Settings"

      # Check for month selector
      assert result =~ "May 2025"
    end

    test "highlights the active route", %{scope: scope, book: book} do
      # Test with budget active
      budget_result =
        render_component(&Sidebar.sidebar/1, %{
          current_path: "/books/#{book.external_id}/budget",
          current_scope: scope
        })

      assert budget_result =~ ~r/<a[^>]*href="\/books\/#{book.external_id}\/budget"[^>]*class="[^"]*bg-primary/

      # Test with reports active
      reports_result =
        render_component(&Sidebar.sidebar/1, %{
          current_path: "/books/#{book.external_id}/reports",
          current_scope: scope
        })

      # Test that the Reports link is highlighted when on the reports page
      assert reports_result =~ ~r/<a[^>]*href="\/books\/#{book.external_id}\/reports"[^>]*class="[^"]*bg-primary/

      # Test with accounts active
      accounts_result =
        render_component(&Sidebar.sidebar/1, %{
          current_path: "/accounts",
          current_scope: scope,
          book: book
        })

      assert accounts_result =~ ~r/<a[^>]*href="\/accounts"[^>]*class="[^"]*bg-primary/
    end

    test "renders book selection dropdown", %{scope: scope, book: book} do
      result =
        render_component(&Sidebar.sidebar/1, %{
          current_path: "/books/#{book.external_id}/budget",
          current_scope: scope
        })

      assert result =~ "<select"
      assert result =~ "My Budget"
      assert result =~ "Family Budget"
      assert result =~ "+ Create New Budget"
    end

    test "renders logout form", %{scope: scope, book: book} do
      result =
        render_component(&Sidebar.sidebar/1, %{
          current_path: "/books/#{book.external_id}/budget",
          current_scope: scope
        })

      assert result =~ ~r/<form[^>]*action="\/users\/log-out"/
      assert result =~ "Log out"
    end

    test "renders user initial in avatar", %{scope: scope, book: book} do
      result =
        render_component(&Sidebar.sidebar/1, %{
          current_path: "/books/#{book.external_id}/budget",
          current_scope: scope
        })

      # The avatar should contain the uppercase first letter of the email
      assert result =~ "<span>T</span>"
    end
  end
end
