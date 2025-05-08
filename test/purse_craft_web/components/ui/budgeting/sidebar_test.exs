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
        render_component(&Sidebar.sidebar/1, %{
          current_path: "/books/#{book.external_id}/budget",
          current_scope: scope
        })

      assert budget_result =~ ~r/<a[^>]*href="\/books\/#{book.external_id}\/budget"[^>]*class="[^"]*bg-primary/

      reports_result =
        render_component(&Sidebar.sidebar/1, %{
          current_path: "/books/#{book.external_id}/reports",
          current_scope: scope
        })

      assert reports_result =~ ~r/<a[^>]*href="\/books\/#{book.external_id}\/reports"[^>]*class="[^"]*bg-primary/

      accounts_result =
        render_component(&Sidebar.sidebar/1, %{
          current_path: "/books/#{book.external_id}/accounts",
          current_scope: scope
        })

      assert accounts_result =~ ~r/<a[^>]*href="\/books\/#{book.external_id}\/accounts"[^>]*class="[^"]*bg-primary/
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

      assert result =~ "<span>T</span>"
    end
  end
end
