defmodule PurseCraftWeb.BudgetLive.IndexTest do
  use PurseCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias PurseCraft.BudgetingFactory

  setup :register_and_log_in_user

  setup %{user: user} do
    book = BudgetingFactory.insert(:book, name: "Test Budget Book")
    BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
    %{book: book}
  end

  describe "Budget page" do
    test "renders budget page elements", %{conn: conn, book: book} do
      {:ok, _view, html} = live(conn, ~p"/books/#{book.external_id}/budget")

      assert html =~ "Budget - #{book.name}"
      assert html =~ "Ready to Assign"
      assert html =~ "Assigned this Month"
      assert html =~ "Activity this Month"
      assert html =~ "Immediate Obligations"
      assert html =~ "True Expenses"
      assert html =~ "Quality of Life"
      assert html =~ "May 2025"
    end

    test "has functioning sidebar links", %{conn: conn, book: book} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      assert has_element?(view, "a", "Budget")
      assert has_element?(view, "a", "Reports")
      assert has_element?(view, "a", "All Accounts")

      budget_link = element(view, "a", "Budget")
      assert render(budget_link) =~ "bg-primary"
    end

    test "renders user email in sidebar", %{conn: conn, book: book, user: user} do
      {:ok, _view, html} = live(conn, ~p"/books/#{book.external_id}/budget")

      assert html =~ user.email
    end

    test "shows budget categories", %{conn: conn, book: book} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      assert has_element?(view, "div", "Rent/Mortgage")
      assert has_element?(view, "div", "Electric")
      assert has_element?(view, "div", "Water")
      assert has_element?(view, "div", "Internet")
      assert has_element?(view, "div", "Groceries")

      html = render(view)
      assert html =~ "Internet"
      assert html =~ "$0.00"

      assert html =~
               ~s(Internet</span><div class="flex gap-8 text-sm"><span class="w-24 text-right">$75.00</span><span class="w-24 text-right">$-75.00</span><span class="w-24 text-right font-medium ">$0.00</span>)
    end

    test "shows action buttons", %{conn: conn, book: book} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      assert has_element?(view, "button", "Add Category")
      assert has_element?(view, "button", "Auto-Assign")
    end

    test "shows all balance styling variants", %{conn: conn, book: book} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      html = render(view)

      assert html =~ "Rent/Mortgage"
      assert html =~ "w-24 text-right font-medium text-success"

      assert html =~ "Internet"
      assert html =~ "$0.00"
      assert html =~ "w-24 text-right font-medium \">$0.00"

      assert html =~ "Overspent"
      assert html =~ "$-25.00"
      assert html =~ "w-24 text-right font-medium text-error"
    end
  end
end
