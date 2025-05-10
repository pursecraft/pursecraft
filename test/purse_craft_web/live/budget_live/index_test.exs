defmodule PurseCraftWeb.BudgetLive.IndexTest do
  use PurseCraftWeb.ConnCase, async: true

  import Mimic
  import Phoenix.LiveViewTest

  alias PurseCraft.BudgetingFactory

  setup :register_and_log_in_user

  setup %{user: user} do
    book = BudgetingFactory.insert(:book, name: "Test Budget Book")
    BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

    housing_category = BudgetingFactory.insert(:category, name: "Housing", book_id: book.id)
    food_category = BudgetingFactory.insert(:category, name: "Food", book_id: book.id)

    BudgetingFactory.insert(:envelope, name: "Rent", category_id: housing_category.id)
    BudgetingFactory.insert(:envelope, name: "Utilities", category_id: housing_category.id)
    BudgetingFactory.insert(:envelope, name: "Groceries", category_id: food_category.id)
    BudgetingFactory.insert(:envelope, name: "Dining Out", category_id: food_category.id)

    %{book: book, categories: [housing_category, food_category]}
  end

  describe "Budget page" do
    test "renders budget page elements", %{conn: conn, book: book} do
      {:ok, _view, html} = live(conn, ~p"/books/#{book.external_id}/budget")

      assert html =~ "Budget - #{book.name}"
      assert html =~ "Ready to Assign"
      assert html =~ "Assigned this Month"
      assert html =~ "Activity this Month"
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

    test "shows budget categories and envelopes from database", %{conn: conn, book: book, categories: categories} do
      {:ok, view, html} = live(conn, ~p"/books/#{book.external_id}/budget")

      assert has_element?(view, "h3", "Housing")
      assert has_element?(view, "h3", "Food")

      assert has_element?(view, "span.font-medium", "Rent")
      assert has_element?(view, "span.font-medium", "Utilities")
      assert has_element?(view, "span.font-medium", "Groceries")
      assert has_element?(view, "span.font-medium", "Dining Out")

      refute html =~ "Immediate Obligations"
      refute html =~ "True Expenses"

      [housing, food] = categories
      assert html =~ ~r/id="categories-#{housing.external_id}"/
      assert html =~ ~r/id="categories-#{food.external_id}"/
    end

    test "shows action buttons", %{conn: conn, book: book} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      assert has_element?(view, "button", "Add Category")
      assert has_element?(view, "button", "Auto-Assign")
    end
  end

  describe "Error handling" do
    test "redirects to books page when book doesn't exist with not_found error", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()

      stub(PurseCraft.Budgeting.Policy, :authorize, fn :book_read, _scope, _book ->
        :ok
      end)

      assert {:error, {:live_redirect, %{to: "/books", flash: %{"error" => "Book not found"}}}} =
               live(conn, ~p"/books/#{non_existent_id}/budget")
    end

    test "redirects to books page when book doesn't exist", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()

      assert {:error, {:live_redirect, %{to: "/books", flash: %{"error" => "You don't have access to this book"}}}} =
               live(conn, ~p"/books/#{non_existent_id}/budget")
    end

    test "redirects to books page when unauthorized", %{conn: conn} do
      book = BudgetingFactory.insert(:book, name: "Someone Else's Budget")

      assert {:error, {:live_redirect, %{to: "/books", flash: %{"error" => "You don't have access to this book"}}}} =
               live(conn, ~p"/books/#{book.external_id}/budget")
    end
  end
end
