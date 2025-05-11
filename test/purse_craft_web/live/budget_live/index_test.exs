defmodule PurseCraftWeb.BudgetLive.IndexTest do
  use PurseCraftWeb.ConnCase, async: true

  import Mimic
  import Phoenix.LiveViewTest

  alias PurseCraft.Budgeting
  alias PurseCraft.Budgeting.Policy
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

  describe "Category Creation" do
    test "opens and closes category modal", %{conn: conn, book: book} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      refute has_element?(view, ".modal-open")

      view
      |> element("button", "Add Category")
      |> render_click()

      assert has_element?(view, ".modal-open")
      assert has_element?(view, "h3", "Add New Category")

      view
      |> element("button", "Cancel")
      |> render_click()

      refute has_element?(view, ".modal-open")

      view
      |> element("button", "Add Category")
      |> render_click()

      assert has_element?(view, ".modal-open")

      view
      |> element(".modal-backdrop")
      |> render_click()

      refute has_element?(view, ".modal-open")
    end

    test "creates new category through modal", %{conn: conn, book: book} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button", "Add Category")
      |> render_click()

      view
      |> form("#category-form", %{category: %{name: "Test Category"}})
      |> render_submit()

      assert has_element?(view, ".alert-info", "Category created successfully")

      refute has_element?(view, ".modal-open")

      assert has_element?(view, "h3", "Test Category")
    end

    test "handles form validation errors for empty name", %{conn: conn, book: book, user: user} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button", "Add Category")
      |> render_click()

      {:error, changeset} =
        Budgeting.create_category(
          %PurseCraft.Identity.Schemas.Scope{user: user},
          book,
          %{name: ""}
        )

      assert changeset.errors[:name]

      view
      |> form("#category-form", %{category: %{name: ""}})
      |> render_submit()

      assert has_element?(view, ".modal-open")
    end

    test "handles unauthorized category creation", %{conn: conn, book: book} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button", "Add Category")
      |> render_click()

      stub(Policy, :authorize, fn :category_create, _scope, _resource ->
        {:error, :unauthorized}
      end)

      view
      |> form("#category-form", %{category: %{name: "Unauthorized Category"}})
      |> render_submit()

      assert has_element?(view, ".alert-error", "You don't have permission to create categories")

      refute has_element?(view, ".modal-open")
    end
  end

  describe "Category Editing" do
    test "when edit button is clicked opens modal", %{conn: conn, book: book, categories: [housing_category, _]} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button[phx-click='edit_category'][phx-value-id='#{housing_category.external_id}']")
      |> render_click()

      assert has_element?(view, ".modal-open")
      assert has_element?(view, "h3", "Edit Category")
      assert has_element?(view, "input[value='Housing']")
      assert has_element?(view, "form[phx-submit='update-category']")
      assert has_element?(view, "button[type='submit']", "Update")
    end

    test "updates category when submitting edit form", %{conn: conn, book: book, categories: [housing_category, _]} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button[phx-click='edit_category'][phx-value-id='#{housing_category.external_id}']")
      |> render_click()

      view
      |> form("#category-form", %{category: %{name: "Updated Housing"}})
      |> render_submit()

      assert has_element?(view, ".alert-info", "Category updated successfully")
      refute has_element?(view, ".modal-open")
      assert has_element?(view, "h3", "Updated Housing")
    end

    test "handles validation errors when updating category", %{conn: conn, book: book, categories: [housing_category, _]} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button[phx-click='edit_category'][phx-value-id='#{housing_category.external_id}']")
      |> render_click()

      view
      |> form("#category-form", %{category: %{name: ""}})
      |> render_submit()

      assert has_element?(view, ".modal-open")
    end

    test "handles unauthorized category update", %{conn: conn, book: book, categories: [housing_category, _]} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button[phx-click='edit_category'][phx-value-id='#{housing_category.external_id}']")
      |> render_click()

      stub(Policy, :authorize, fn :category_update, _scope, _resource ->
        {:error, :unauthorized}
      end)

      view
      |> form("#category-form", %{category: %{name: "Updated Housing"}})
      |> render_submit()

      assert has_element?(view, ".alert-error", "You don't have permission to update categories")
      refute has_element?(view, ".modal-open")
    end

    test "correctly resets form when canceling edit", %{conn: conn, book: book, categories: [housing_category, _]} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button[phx-click='edit_category'][phx-value-id='#{housing_category.external_id}']")
      |> render_click()

      view
      |> element("button", "Cancel")
      |> render_click()

      refute has_element?(view, ".modal-open")

      view
      |> element("button", "Add Category")
      |> render_click()

      assert has_element?(view, "h3", "Add New Category")
      assert has_element?(view, "button[type='submit']", "Create")
      assert has_element?(view, "form[phx-submit='create-category']")
    end
  end

  describe "Error handling" do
    test "redirects to books page when book doesn't exist with not_found error", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()

      stub(Policy, :authorize, fn :book_read, _scope, _book ->
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
