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

    category = BudgetingFactory.insert(:category, name: "Housing", book_id: book.id)
    envelope = BudgetingFactory.insert(:envelope, name: "Rent", category_id: category.id)
    category_with_envelope = %{category | envelopes: [envelope]}

    %{
      book: book,
      category: category_with_envelope,
      envelope: envelope
    }
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

    test "shows budget category and envelope from database", %{conn: conn, book: book, category: category} do
      {:ok, view, html} = live(conn, ~p"/books/#{book.external_id}/budget")

      assert has_element?(view, "h3", "Housing")
      assert has_element?(view, "span.font-medium", "Rent")

      refute html =~ "Immediate Obligations"
      refute html =~ "True Expenses"

      assert html =~ ~r/id="categories-#{category.external_id}"/
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
    test "when edit button is clicked opens modal", %{conn: conn, book: book, category: category} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button[phx-click='edit_category'][phx-value-id='#{category.external_id}']")
      |> render_click()

      assert has_element?(view, ".modal-open")
      assert has_element?(view, "h3", "Edit Category")
      assert has_element?(view, "input[value='Housing']")
      assert has_element?(view, "form[phx-submit='update-category']")
      assert has_element?(view, "button[type='submit']", "Update")
    end

    test "updates category when submitting edit form", %{conn: conn, book: book, category: category} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button[phx-click='edit_category'][phx-value-id='#{category.external_id}']")
      |> render_click()

      view
      |> form("#category-form", %{category: %{name: "Updated Housing"}})
      |> render_submit()

      assert has_element?(view, ".alert-info", "Category updated successfully")
      refute has_element?(view, ".modal-open")
      assert has_element?(view, "h3", "Updated Housing")
    end

    test "handles validation errors when updating category", %{conn: conn, book: book, category: category} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button[phx-click='edit_category'][phx-value-id='#{category.external_id}']")
      |> render_click()

      view
      |> form("#category-form", %{category: %{name: ""}})
      |> render_submit()

      assert has_element?(view, ".modal-open")
    end

    test "handles unauthorized category update", %{conn: conn, book: book, category: category} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button[phx-click='edit_category'][phx-value-id='#{category.external_id}']")
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

    test "correctly resets form when canceling edit", %{conn: conn, book: book, category: category} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button[phx-click='edit_category'][phx-value-id='#{category.external_id}']")
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

    test "shows error when category is not found during edit", %{conn: conn, book: book} do
      non_existent_id = Ecto.UUID.generate()
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      stub(Budgeting, :fetch_category_by_external_id, fn _scope, _book, _external_id ->
        {:error, :not_found}
      end)

      render_click(view, "edit_category", %{"id" => non_existent_id})

      assert has_element?(view, ".alert-error", "Category not found")
    end

    test "shows error when unauthorized to edit category", %{conn: conn, book: book, category: category} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      stub(Budgeting, :fetch_category_by_external_id, fn _scope, _book, _external_id ->
        {:error, :unauthorized}
      end)

      render_click(view, "edit_category", %{"id" => category.external_id})

      assert has_element?(view, ".alert-error", "You don't have permission to edit this category")
    end
  end

  describe "Category Deletion" do
    setup %{book: book} do
      empty_category = BudgetingFactory.insert(:category, name: "Empty Category", book_id: book.id)

      %{empty_category: empty_category}
    end

    test "delete button only appears for categories without envelopes", %{
      conn: conn,
      book: book,
      category: category_with_envelope,
      empty_category: empty_category
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      refute has_element?(
               view,
               "button[phx-click='open_delete_modal'][phx-value-id='#{category_with_envelope.external_id}']"
             )

      assert has_element?(
               view,
               "button[phx-click='open_delete_modal'][phx-value-id='#{empty_category.external_id}']"
             )
    end

    test "opens delete confirmation modal when delete button is clicked", %{
      conn: conn,
      book: book,
      empty_category: empty_category
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button[phx-click='open_delete_modal'][phx-value-id='#{empty_category.external_id}']")
      |> render_click()

      assert has_element?(view, ".modal-open")
      assert has_element?(view, "h3", "Delete Category")
      assert has_element?(view, "p", ~r/Are you sure you want to delete the category "Empty Category"\?/)
      assert has_element?(view, "button", "Cancel")
      assert has_element?(view, "button", "Delete")
    end

    test "cancels deletion when cancel button is clicked", %{
      conn: conn,
      book: book,
      empty_category: empty_category
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button[phx-click='open_delete_modal'][phx-value-id='#{empty_category.external_id}']")
      |> render_click()

      assert has_element?(view, ".modal-open")

      view
      |> element("button", "Cancel")
      |> render_click()

      refute has_element?(view, ".modal-open")
    end

    test "successfully deletes category when confirmed", %{
      conn: conn,
      book: book,
      empty_category: empty_category
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button[phx-click='open_delete_modal'][phx-value-id='#{empty_category.external_id}']")
      |> render_click()

      view
      |> element("button.btn-error", "Delete")
      |> render_click()

      assert has_element?(view, ".alert-info", "Category deleted successfully")
      refute has_element?(view, "h3", "Empty Category")
    end

    test "handles unauthorized category deletion", %{
      conn: conn,
      book: book,
      empty_category: empty_category
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button[phx-click='open_delete_modal'][phx-value-id='#{empty_category.external_id}']")
      |> render_click()

      stub(Budgeting, :delete_category, fn _scope, _book, _category ->
        {:error, :unauthorized}
      end)

      view
      |> element("button.btn-error", "Delete")
      |> render_click()

      assert has_element?(view, ".alert-error", "You don't have permission to delete this category")
    end

    test "handles general error when deleting category", %{
      conn: conn,
      book: book,
      empty_category: empty_category
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button[phx-click='open_delete_modal'][phx-value-id='#{empty_category.external_id}']")
      |> render_click()

      stub(Budgeting, :delete_category, fn _scope, _book, _category ->
        {:error, %Ecto.Changeset{}}
      end)

      view
      |> element("button.btn-error", "Delete")
      |> render_click()

      assert has_element?(view, ".alert-error", "Error deleting category")
    end

    test "shows error when category is not found during open_delete_modal", %{conn: conn, book: book} do
      non_existent_id = Ecto.UUID.generate()
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      stub(Budgeting, :fetch_category_by_external_id, fn _scope, _book, _external_id, _opts ->
        {:error, :not_found}
      end)

      render_click(view, "open_delete_modal", %{"id" => non_existent_id})

      assert has_element?(view, ".alert-error", "Category not found")
    end

    test "shows error when unauthorized to open delete modal", %{conn: conn, book: book, empty_category: empty_category} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      stub(Budgeting, :fetch_category_by_external_id, fn _scope, _book, _external_id, _opts ->
        {:error, :unauthorized}
      end)

      render_click(view, "open_delete_modal", %{"id" => empty_category.external_id})

      assert has_element?(view, ".alert-error", "You don't have permission to delete this category")
    end
  end

  describe "Envelope Deletion" do
    test "opens delete confirmation modal when delete button is clicked", %{
      conn: conn,
      book: book,
      category: category,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _book_param, external_id, _opts ->
        if external_id == envelope.external_id do
          {:ok, %{envelope | category: category}}
        else
          {:error, :not_found}
        end
      end)

      view
      |> element("button[phx-click='open_delete_envelope_modal'][phx-value-id='#{envelope.external_id}']")
      |> render_click()

      assert has_element?(view, ".modal-open")
      assert has_element?(view, "h3", "Delete Envelope")
      assert has_element?(view, "p", ~r/Are you sure you want to delete the envelope "Rent"\?/)
      assert has_element?(view, "button", "Cancel")
      assert has_element?(view, "button", "Delete")
    end

    test "cancels deletion when cancel button is clicked", %{
      conn: conn,
      book: book,
      category: category,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _book_param, external_id, _opts ->
        if external_id == envelope.external_id do
          {:ok, %{envelope | category: category}}
        else
          {:error, :not_found}
        end
      end)

      view
      |> element("button[phx-click='open_delete_envelope_modal'][phx-value-id='#{envelope.external_id}']")
      |> render_click()

      assert has_element?(view, ".modal-open")

      view
      |> element("button", "Cancel")
      |> render_click()

      refute has_element?(view, ".modal-open")
    end

    test "successfully deletes envelope when confirmed", %{
      conn: conn,
      book: book,
      category: category,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _book_param, external_id, _opts ->
        if external_id == envelope.external_id do
          {:ok, %{envelope | category: category}}
        else
          {:error, :not_found}
        end
      end)

      view
      |> element("button[phx-click='open_delete_envelope_modal'][phx-value-id='#{envelope.external_id}']")
      |> render_click()

      stub(Budgeting, :delete_envelope, fn _scope, _book, _envelope ->
        # Return successful deletion
        {:ok, envelope}
      end)

      view
      |> element("button.btn-error", "Delete")
      |> render_click()

      assert has_element?(view, ".alert-info", "Envelope deleted successfully")
      refute has_element?(view, "span.font-medium", "Rent")
    end

    test "handles unauthorized envelope deletion", %{
      conn: conn,
      book: book,
      category: category,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _book_param, external_id, _opts ->
        if external_id == envelope.external_id do
          {:ok, %{envelope | category: category}}
        else
          {:error, :not_found}
        end
      end)

      view
      |> element("button[phx-click='open_delete_envelope_modal'][phx-value-id='#{envelope.external_id}']")
      |> render_click()

      stub(Budgeting, :delete_envelope, fn _scope, _book, _envelope ->
        {:error, :unauthorized}
      end)

      view
      |> element("button.btn-error", "Delete")
      |> render_click()

      assert has_element?(view, ".alert-error", "You don't have permission to delete this envelope")
    end

    test "handles general error when deleting envelope", %{
      conn: conn,
      book: book,
      category: category,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _book_param, external_id, _opts ->
        if external_id == envelope.external_id do
          {:ok, %{envelope | category: category}}
        else
          {:error, :not_found}
        end
      end)

      view
      |> element("button[phx-click='open_delete_envelope_modal'][phx-value-id='#{envelope.external_id}']")
      |> render_click()

      stub(Budgeting, :delete_envelope, fn _scope, _book, _envelope ->
        {:error, %Ecto.Changeset{}}
      end)

      view
      |> element("button.btn-error", "Delete")
      |> render_click()

      assert has_element?(view, ".alert-error", "Error deleting envelope")
    end

    test "shows error when envelope is not found during open_delete_envelope_modal", %{
      conn: conn,
      book: book
    } do
      non_existent_id = Ecto.UUID.generate()
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _book, _external_id, _opts ->
        {:error, :not_found}
      end)

      render_click(view, "open_delete_envelope_modal", %{"id" => non_existent_id})

      assert has_element?(view, ".alert-error", "Envelope not found")
    end

    test "shows error when unauthorized to open delete envelope modal", %{
      conn: conn,
      book: book,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _book, _external_id, _opts ->
        {:error, :unauthorized}
      end)

      render_click(view, "open_delete_envelope_modal", %{"id" => envelope.external_id})

      assert has_element?(view, ".alert-error", "You don't have permission to delete this envelope")
    end
  end

  describe "Envelope Editing" do
    test "when edit button is clicked opens edit modal", %{
      conn: conn,
      book: book,
      category: category,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _book_param, external_id, _opts ->
        if external_id == envelope.external_id do
          {:ok, %{envelope | category: category}}
        else
          {:error, :not_found}
        end
      end)

      view
      |> element("button[phx-click='edit_envelope'][phx-value-id='#{envelope.external_id}']")
      |> render_click()

      assert has_element?(view, ".modal-open")
      assert has_element?(view, "h3", "Edit Envelope")
      assert has_element?(view, "input[value='Rent']")
      assert has_element?(view, "form[phx-submit='update-envelope']")
      assert has_element?(view, "button[type='submit']", "Update")
    end

    test "updates envelope when submitting edit form", %{
      conn: conn,
      book: book,
      category: category,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      # Mock the necessary functions for fetching and preloading
      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _book_param, external_id, _opts ->
        if external_id == envelope.external_id do
          {:ok, %{envelope | category: category}}
        else
          {:error, :not_found}
        end
      end)

      view
      |> element("button[phx-click='edit_envelope'][phx-value-id='#{envelope.external_id}']")
      |> render_click()

      stub(Budgeting, :update_envelope, fn _scope, _book_param, _envelope, envelope_params ->
        updated_envelope = %{envelope | name: envelope_params[:name]}
        {:ok, updated_envelope}
      end)

      view
      |> form("#envelope-form", %{envelope: %{name: "Updated Rent"}})
      |> render_submit()

      assert has_element?(view, ".alert-info", "Envelope updated successfully")
      refute has_element?(view, ".modal-open")
    end

    test "handles validation errors when updating envelope", %{
      conn: conn,
      book: book,
      category: category,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _book_param, external_id, _opts ->
        if external_id == envelope.external_id do
          {:ok, %{envelope | category: category}}
        else
          {:error, :not_found}
        end
      end)

      view
      |> element("button[phx-click='edit_envelope'][phx-value-id='#{envelope.external_id}']")
      |> render_click()

      stub(Budgeting, :update_envelope, fn _scope, _book_param, _envelope, _envelope_params ->
        changeset = Ecto.Changeset.change(envelope)
        changeset = Ecto.Changeset.add_error(changeset, :name, "can't be blank")
        {:error, changeset}
      end)

      view
      |> form("#envelope-form", %{envelope: %{name: ""}})
      |> render_submit()

      assert has_element?(view, ".modal-open")
    end

    test "handles unauthorized envelope update", %{
      conn: conn,
      book: book,
      category: category,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _book_param, external_id, _opts ->
        if external_id == envelope.external_id do
          {:ok, %{envelope | category: category}}
        else
          {:error, :not_found}
        end
      end)

      view
      |> element("button[phx-click='edit_envelope'][phx-value-id='#{envelope.external_id}']")
      |> render_click()

      stub(Budgeting, :update_envelope, fn _scope, _book_param, _envelope, _envelope_params ->
        {:error, :unauthorized}
      end)

      view
      |> form("#envelope-form", %{envelope: %{name: "Updated Rent"}})
      |> render_submit()

      assert has_element?(view, ".alert-error", "You don't have permission to update envelopes")
      refute has_element?(view, ".modal-open")
    end

    test "shows error when envelope is not found during edit", %{conn: conn, book: book} do
      non_existent_id = Ecto.UUID.generate()
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _book_param, _external_id, _opts ->
        {:error, :not_found}
      end)

      render_click(view, "edit_envelope", %{"id" => non_existent_id})

      assert has_element?(view, ".alert-error", "Envelope not found")
    end

    test "shows error when unauthorized to edit envelope", %{
      conn: conn,
      book: book,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _book_param, _external_id, _opts ->
        {:error, :unauthorized}
      end)

      render_click(view, "edit_envelope", %{"id" => envelope.external_id})

      assert has_element?(view, ".alert-error", "You don't have permission to edit this envelope")
    end

    test "correctly resets form when canceling edit", %{
      conn: conn,
      book: book,
      category: category,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _book_param, external_id, _opts ->
        if external_id == envelope.external_id do
          {:ok, %{envelope | category: category}}
        else
          {:error, :not_found}
        end
      end)

      view
      |> element("button[phx-click='edit_envelope'][phx-value-id='#{envelope.external_id}']")
      |> render_click()

      assert has_element?(view, ".modal-open")
      assert has_element?(view, "h3", "Edit Envelope")

      view
      |> element("button", "Cancel")
      |> render_click()

      refute has_element?(view, ".modal-open")

      view
      |> element("button[phx-click='open_envelope_modal'][phx-value-id='#{category.external_id}']")
      |> render_click()

      assert has_element?(view, "h3", "Add New Envelope")
      assert has_element?(view, "button[type='submit']", "Create")
      assert has_element?(view, "form[phx-submit='create-envelope']")
    end
  end

  describe "Envelope Creation" do
    test "opens envelope modal when + button is clicked", %{
      conn: conn,
      book: book,
      category: category
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button[phx-click='open_envelope_modal'][phx-value-id='#{category.external_id}']")
      |> render_click()

      assert has_element?(view, ".modal-open")
      assert has_element?(view, "h3", "Add New Envelope")
      assert has_element?(view, "form[phx-submit='create-envelope']")
      assert has_element?(view, "label", "Envelope Name")
    end

    test "closes envelope modal when cancel button is clicked", %{
      conn: conn,
      book: book,
      category: category
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button[phx-click='open_envelope_modal'][phx-value-id='#{category.external_id}']")
      |> render_click()

      assert has_element?(view, ".modal-open")

      view
      |> element("button", "Cancel")
      |> render_click()

      refute has_element?(view, ".modal-open")
    end

    test "closes envelope modal when clicking backdrop", %{
      conn: conn,
      book: book,
      category: category
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button[phx-click='open_envelope_modal'][phx-value-id='#{category.external_id}']")
      |> render_click()

      assert has_element?(view, ".modal-open")

      view
      |> element(".modal-backdrop")
      |> render_click()

      refute has_element?(view, ".modal-open")
    end

    test "creates a new envelope successfully", %{conn: conn, book: book, category: category} do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button[phx-click='open_envelope_modal'][phx-value-id='#{category.external_id}']")
      |> render_click()

      view
      |> form("#envelope-form", %{envelope: %{name: "New Home Insurance"}})
      |> render_submit()

      assert has_element?(view, ".alert-info", "Envelope created successfully")
      refute has_element?(view, ".modal-open")
      assert has_element?(view, "span.font-medium", "New Home Insurance")
    end

    test "handles validation errors when creating an envelope", %{
      conn: conn,
      book: book,
      category: category
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button[phx-click='open_envelope_modal'][phx-value-id='#{category.external_id}']")
      |> render_click()

      view
      |> form("#envelope-form", %{envelope: %{name: ""}})
      |> render_submit()

      assert has_element?(view, ".modal-open")
    end

    test "handles unauthorized envelope creation", %{
      conn: conn,
      book: book,
      category: category
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      view
      |> element("button[phx-click='open_envelope_modal'][phx-value-id='#{category.external_id}']")
      |> render_click()

      stub(Policy, :authorize, fn :envelope_create, _scope, _resource ->
        {:error, :unauthorized}
      end)

      view
      |> form("#envelope-form", %{envelope: %{name: "Unauthorized Envelope"}})
      |> render_submit()

      assert has_element?(view, ".alert-error", "You don't have permission to create envelopes")
      refute has_element?(view, ".modal-open")
    end

    test "shows error when category is not found during open_envelope_modal", %{conn: conn, book: book} do
      non_existent_id = Ecto.UUID.generate()
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      stub(Budgeting, :fetch_category_by_external_id, fn _scope, _book, _external_id, _opts ->
        {:error, :not_found}
      end)

      render_click(view, "open_envelope_modal", %{"id" => non_existent_id})

      assert has_element?(view, ".alert-error", "Category not found")
    end

    test "shows error when unauthorized to open envelope modal", %{
      conn: conn,
      book: book,
      category: category
    } do
      {:ok, view, _html} = live(conn, ~p"/books/#{book.external_id}/budget")

      stub(Budgeting, :fetch_category_by_external_id, fn _scope, _book, _external_id, _opts ->
        {:error, :unauthorized}
      end)

      render_click(view, "open_envelope_modal", %{"id" => category.external_id})

      assert has_element?(view, ".alert-error", "You don't have permission to access this category")
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

    test "redirects when categories access is unauthorized", %{conn: conn, book: book} do
      stub(Budgeting, :fetch_book_by_external_id, fn _scope, _external_id ->
        {:ok, book}
      end)

      stub(Budgeting, :list_categories, fn _scope, _book, _opts ->
        {:error, :unauthorized}
      end)

      assert {:error,
              {:live_redirect, %{to: "/books", flash: %{"error" => "You don't have access to this book's categories"}}}} =
               live(conn, ~p"/books/#{book.external_id}/budget")
    end
  end
end
