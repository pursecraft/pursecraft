defmodule PurseCraftWeb.ReportsLive.IndexTest do
  use PurseCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias PurseCraft.BudgetingFactory

  setup :register_and_log_in_user

  setup %{user: user} do
    book = BudgetingFactory.insert(:book, name: "Test Reports Book")
    BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
    %{book: book}
  end

  describe "Reports page" do
    test "renders reports page elements", %{conn: conn, book: book} do
      {:ok, _view, html} = live(conn, ~p"/books/#{book.external_id}/reports")

      assert html =~ "Reports - #{book.name}"
      assert html =~ "Spending Trends"
      assert html =~ "Top Categories"
      assert html =~ "Income vs Spending"
    end

    test "has functioning sidebar links", %{conn: conn, book: book} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/reports")

      # Check sidebar links are present
      assert has_element?(view, "a", "Budget")
      assert has_element?(view, "a", "Reports")
      assert has_element?(view, "a", "All Accounts")

      # The Reports link should be highlighted as active
      reports_link = element(view, "a", "Reports")
      assert render(reports_link) =~ "bg-primary"
    end

    test "renders user email in sidebar", %{conn: conn, user: user, book: book} do
      {:ok, _view, html} = live(conn, ~p"/books/#{book.external_id}/reports")

      assert html =~ user.email
    end

    test "shows export button", %{conn: conn, book: book} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/reports")

      assert has_element?(view, "button", "Export")
    end

    test "shows chart placeholders", %{conn: conn, book: book} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/reports")

      assert has_element?(view, "p", "Chart visualization will be implemented here")
      assert has_element?(view, "p", "Pie chart will be implemented here")
      assert has_element?(view, "p", "Bar chart will be implemented here")
    end

    test "verifies current_path is set correctly", %{conn: conn, book: book} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/reports")

      # This is to test that the mount function is setting current_path correctly
      assert render(view) =~ "/books/#{book.external_id}/reports"

      # Test page title is set correctly
      assert page_title(view) =~ "Reports - #{book.name}"
    end
  end
end
