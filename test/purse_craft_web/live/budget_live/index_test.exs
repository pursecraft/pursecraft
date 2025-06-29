defmodule PurseCraftWeb.BudgetLive.IndexTest do
  use PurseCraftWeb.ConnCase, async: true

  import Mimic
  import Phoenix.LiveViewTest

  alias PurseCraft.Budgeting
  alias PurseCraft.Budgeting.Commands.Categories.RepositionCategory
  alias PurseCraft.Budgeting.Commands.Envelopes.RepositionEnvelope
  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.CategoryRepository
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.Core.Commands.Workspaces.FetchWorkspaceByExternalId
  alias PurseCraft.CoreFactory

  setup :register_and_log_in_user

  setup %{user: user} do
    workspace = CoreFactory.insert(:workspace, name: "Test Budget Workspace")
    CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

    category = BudgetingFactory.insert(:category, name: "Housing", workspace_id: workspace.id)
    envelope = BudgetingFactory.insert(:envelope, name: "Rent", category_id: category.id)
    category_with_envelope = %{category | envelopes: [envelope]}

    %{
      workspace: workspace,
      category: category_with_envelope,
      envelope: envelope
    }
  end

  describe "Budget page" do
    test "renders budget page elements", %{conn: conn, workspace: workspace} do
      {:ok, _view, html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      assert html =~ "Budget - #{workspace.name}"
      assert html =~ "Ready to Assign"
      assert html =~ "Assigned this Month"
      assert html =~ "Activity this Month"
      assert html =~ "May 2025"
    end

    test "has functioning sidebar links", %{conn: conn, workspace: workspace} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      assert has_element?(view, "a", "Budget")
      assert has_element?(view, "a", "Reports")
      assert has_element?(view, "a", "All Accounts")

      budget_link = element(view, "a", "Budget")
      assert render(budget_link) =~ "bg-primary"
    end

    test "renders user email in sidebar", %{conn: conn, workspace: workspace, user: user} do
      {:ok, _view, html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      assert html =~ user.email
    end

    test "shows budget category and envelope from database", %{conn: conn, workspace: workspace, category: category} do
      {:ok, view, html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      assert has_element?(view, "h3", "Housing")
      assert has_element?(view, "span.font-medium", "Rent")

      refute html =~ "Immediate Obligations"
      refute html =~ "True Expenses"

      assert html =~ ~r/id="categories-#{category.external_id}"/
    end

    test "shows action buttons", %{conn: conn, workspace: workspace} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      assert has_element?(view, "button", "Add Category")
      assert has_element?(view, "button", "Auto-Assign")
    end
  end

  describe "Category Creation" do
    test "opens and closes category modal", %{conn: conn, workspace: workspace} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

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

    test "creates new category through modal", %{conn: conn, workspace: workspace} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

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

    test "handles form validation errors for empty name", %{conn: conn, workspace: workspace} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      view
      |> element("button", "Add Category")
      |> render_click()

      view
      |> form("#category-form", %{category: %{name: ""}})
      |> render_submit()

      assert has_element?(view, ".modal-open")
    end

    test "handles unauthorized category creation", %{conn: conn, workspace: workspace} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

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
    test "when edit button is clicked opens modal", %{conn: conn, workspace: workspace, category: category} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      view
      |> element("button[phx-click='edit_category'][phx-value-id='#{category.external_id}']")
      |> render_click()

      assert has_element?(view, ".modal-open")
      assert has_element?(view, "h3", "Edit Category")
      assert has_element?(view, "input[value='Housing']")
      assert has_element?(view, "form[phx-submit='save_category']")
      assert has_element?(view, "button[type='submit']", "Update")
    end

    test "updates category when submitting edit form", %{conn: conn, workspace: workspace, category: category} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

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

    test "handles validation errors when updating category", %{conn: conn, workspace: workspace, category: category} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      view
      |> element("button[phx-click='edit_category'][phx-value-id='#{category.external_id}']")
      |> render_click()

      view
      |> form("#category-form", %{category: %{name: ""}})
      |> render_submit()

      assert has_element?(view, ".modal-open")
    end

    test "handles unauthorized category update", %{conn: conn, workspace: workspace, category: category} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

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

    test "correctly resets form when canceling edit", %{conn: conn, workspace: workspace, category: category} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

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
      assert has_element?(view, "form[phx-submit='save_category']")
    end

    test "shows error when category is not found during edit", %{conn: conn, workspace: workspace} do
      non_existent_id = Ecto.UUID.generate()
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(Budgeting, :fetch_category_by_external_id, fn _scope, _workspace, _external_id ->
        {:error, :not_found}
      end)

      render_click(view, "edit_category", %{"id" => non_existent_id})

      assert has_element?(view, ".alert-error", "Category not found")
    end

    test "shows error when unauthorized to edit category", %{conn: conn, workspace: workspace, category: category} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(Budgeting, :fetch_category_by_external_id, fn _scope, _workspace, _external_id ->
        {:error, :unauthorized}
      end)

      render_click(view, "edit_category", %{"id" => category.external_id})

      assert has_element?(view, ".alert-error", "You don't have permission to edit this category")
    end
  end

  describe "Category Deletion" do
    setup %{workspace: workspace} do
      empty_category = BudgetingFactory.insert(:category, name: "Empty Category", workspace_id: workspace.id)

      %{empty_category: empty_category}
    end

    test "delete button only appears for categories without envelopes", %{
      conn: conn,
      workspace: workspace,
      category: category_with_envelope,
      empty_category: empty_category
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      refute has_element?(
               view,
               "button[phx-click='delete_category_confirm'][phx-value-id='#{category_with_envelope.external_id}']"
             )

      assert has_element?(
               view,
               "button[phx-click='delete_category_confirm'][phx-value-id='#{empty_category.external_id}']"
             )
    end

    test "opens delete confirmation modal when delete button is clicked", %{
      conn: conn,
      workspace: workspace,
      empty_category: empty_category
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      view
      |> element("button[phx-click='delete_category_confirm'][phx-value-id='#{empty_category.external_id}']")
      |> render_click()

      assert has_element?(view, ".modal-open")
      assert has_element?(view, "h3", "Delete Category")
      assert has_element?(view, "p", ~r/Are you sure you want to delete the category "Empty Category"\?/)
      assert has_element?(view, "button", "Cancel")
      assert has_element?(view, "button", "Delete")
    end

    test "cancels deletion when cancel button is clicked", %{
      conn: conn,
      workspace: workspace,
      empty_category: empty_category
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      view
      |> element("button[phx-click='delete_category_confirm'][phx-value-id='#{empty_category.external_id}']")
      |> render_click()

      assert has_element?(view, ".modal-open")

      view
      |> element("button", "Cancel")
      |> render_click()

      refute has_element?(view, ".modal-open")
    end

    test "successfully deletes category when confirmed", %{
      conn: conn,
      workspace: workspace,
      empty_category: empty_category
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      view
      |> element("button[phx-click='delete_category_confirm'][phx-value-id='#{empty_category.external_id}']")
      |> render_click()

      view
      |> element("button.btn-error", "Delete")
      |> render_click()

      assert has_element?(view, ".alert-info", "Category deleted successfully")
      refute has_element?(view, "h3", "Empty Category")
    end

    test "handles unauthorized category deletion", %{
      conn: conn,
      workspace: workspace,
      empty_category: empty_category
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      view
      |> element("button[phx-click='delete_category_confirm'][phx-value-id='#{empty_category.external_id}']")
      |> render_click()

      stub(Budgeting, :delete_category, fn _scope, _workspace, _category ->
        {:error, :unauthorized}
      end)

      view
      |> element("button.btn-error", "Delete")
      |> render_click()

      assert has_element?(view, ".alert-error", "You don't have permission to delete this category")
    end

    test "handles general error when deleting category", %{
      conn: conn,
      workspace: workspace,
      empty_category: empty_category
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      view
      |> element("button[phx-click='delete_category_confirm'][phx-value-id='#{empty_category.external_id}']")
      |> render_click()

      stub(Budgeting, :delete_category, fn _scope, _workspace, _category ->
        {:error, %Ecto.Changeset{}}
      end)

      view
      |> element("button.btn-error", "Delete")
      |> render_click()

      assert has_element?(view, ".alert-error", "Error deleting category")
    end

    test "shows error when category is not found during delete_category_confirm", %{conn: conn, workspace: workspace} do
      non_existent_id = Ecto.UUID.generate()
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(Budgeting, :fetch_category_by_external_id, fn _scope, _workspace, _external_id, _opts ->
        {:error, :not_found}
      end)

      render_click(view, "delete_category_confirm", %{"id" => non_existent_id})

      assert has_element?(view, ".alert-error", "Category not found")
    end

    test "shows error when unauthorized to open delete modal", %{
      conn: conn,
      workspace: workspace,
      empty_category: empty_category
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(Budgeting, :fetch_category_by_external_id, fn _scope, _workspace, _external_id, _opts ->
        {:error, :unauthorized}
      end)

      render_click(view, "delete_category_confirm", %{"id" => empty_category.external_id})

      assert has_element?(view, ".alert-error", "You don't have permission to delete this category")
    end
  end

  describe "Envelope Deletion" do
    test "opens delete confirmation modal when delete button is clicked", %{
      conn: conn,
      workspace: workspace,
      category: category,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _workspace_param, external_id, _opts ->
        if external_id == envelope.external_id do
          {:ok, %{envelope | category: category}}
        else
          {:error, :not_found}
        end
      end)

      view
      |> element("button[phx-click='delete_envelope_confirm'][phx-value-id='#{envelope.external_id}']")
      |> render_click()

      assert has_element?(view, ".modal-open")
      assert has_element?(view, "h3", "Delete Envelope")
      assert has_element?(view, "p", ~r/Are you sure you want to delete the envelope "Rent"\?/)
      assert has_element?(view, "button", "Cancel")
      assert has_element?(view, "button", "Delete")
    end

    test "cancels deletion when cancel button is clicked", %{
      conn: conn,
      workspace: workspace,
      category: category,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _workspace_param, external_id, _opts ->
        if external_id == envelope.external_id do
          {:ok, %{envelope | category: category}}
        else
          {:error, :not_found}
        end
      end)

      view
      |> element("button[phx-click='delete_envelope_confirm'][phx-value-id='#{envelope.external_id}']")
      |> render_click()

      assert has_element?(view, ".modal-open")

      view
      |> element("button", "Cancel")
      |> render_click()

      refute has_element?(view, ".modal-open")
    end

    test "successfully deletes envelope when confirmed", %{
      conn: conn,
      workspace: workspace,
      category: category,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _workspace_param, external_id, _opts ->
        if external_id == envelope.external_id do
          {:ok, %{envelope | category: category}}
        else
          {:error, :not_found}
        end
      end)

      view
      |> element("button[phx-click='delete_envelope_confirm'][phx-value-id='#{envelope.external_id}']")
      |> render_click()

      stub(Budgeting, :delete_envelope, fn _scope, _workspace, _envelope ->
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
      workspace: workspace,
      category: category,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _workspace_param, external_id, _opts ->
        if external_id == envelope.external_id do
          {:ok, %{envelope | category: category}}
        else
          {:error, :not_found}
        end
      end)

      view
      |> element("button[phx-click='delete_envelope_confirm'][phx-value-id='#{envelope.external_id}']")
      |> render_click()

      stub(Budgeting, :delete_envelope, fn _scope, _workspace, _envelope ->
        {:error, :unauthorized}
      end)

      view
      |> element("button.btn-error", "Delete")
      |> render_click()

      assert has_element?(view, ".alert-error", "You don't have permission to delete this envelope")
    end

    test "handles general error when deleting envelope", %{
      conn: conn,
      workspace: workspace,
      category: category,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _workspace_param, external_id, _opts ->
        if external_id == envelope.external_id do
          {:ok, %{envelope | category: category}}
        else
          {:error, :not_found}
        end
      end)

      view
      |> element("button[phx-click='delete_envelope_confirm'][phx-value-id='#{envelope.external_id}']")
      |> render_click()

      stub(Budgeting, :delete_envelope, fn _scope, _workspace, _envelope ->
        {:error, %Ecto.Changeset{}}
      end)

      view
      |> element("button.btn-error", "Delete")
      |> render_click()

      assert has_element?(view, ".alert-error", "Error deleting envelope")
    end

    test "shows error when envelope is not found during delete_envelope_confirm", %{
      conn: conn,
      workspace: workspace
    } do
      non_existent_id = Ecto.UUID.generate()
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _workspace, _external_id, _opts ->
        {:error, :not_found}
      end)

      render_click(view, "delete_envelope_confirm", %{"id" => non_existent_id})

      assert has_element?(view, ".alert-error", "Envelope not found")
    end

    test "shows error when unauthorized to open delete envelope modal", %{
      conn: conn,
      workspace: workspace,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _workspace, _external_id, _opts ->
        {:error, :unauthorized}
      end)

      render_click(view, "delete_envelope_confirm", %{"id" => envelope.external_id})

      assert has_element?(view, ".alert-error", "You don't have permission to delete this envelope")
    end
  end

  describe "Envelope Editing" do
    test "when edit button is clicked opens edit modal", %{
      conn: conn,
      workspace: workspace,
      category: category,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _workspace_param, external_id, _opts ->
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
      assert has_element?(view, "form[phx-submit='save_envelope']")
      assert has_element?(view, "button[type='submit']", "Update")
    end

    test "updates envelope when submitting edit form", %{
      conn: conn,
      workspace: workspace,
      category: category,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _workspace_param, external_id, _opts ->
        if external_id == envelope.external_id do
          {:ok, %{envelope | category: category}}
        else
          {:error, :not_found}
        end
      end)

      view
      |> element("button[phx-click='edit_envelope'][phx-value-id='#{envelope.external_id}']")
      |> render_click()

      stub(Budgeting, :update_envelope, fn _scope, _workspace_param, _envelope, envelope_params ->
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
      workspace: workspace,
      category: category,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _workspace_param, external_id, _opts ->
        if external_id == envelope.external_id do
          {:ok, %{envelope | category: category}}
        else
          {:error, :not_found}
        end
      end)

      view
      |> element("button[phx-click='edit_envelope'][phx-value-id='#{envelope.external_id}']")
      |> render_click()

      stub(Budgeting, :update_envelope, fn _scope, _workspace_param, _envelope, _envelope_params ->
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
      workspace: workspace,
      category: category,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _workspace_param, external_id, _opts ->
        if external_id == envelope.external_id do
          {:ok, %{envelope | category: category}}
        else
          {:error, :not_found}
        end
      end)

      view
      |> element("button[phx-click='edit_envelope'][phx-value-id='#{envelope.external_id}']")
      |> render_click()

      stub(Budgeting, :update_envelope, fn _scope, _workspace_param, _envelope, _envelope_params ->
        {:error, :unauthorized}
      end)

      view
      |> form("#envelope-form", %{envelope: %{name: "Updated Rent"}})
      |> render_submit()

      assert has_element?(view, ".alert-error", "You don't have permission to update envelopes")
      refute has_element?(view, ".modal-open")
    end

    test "shows error when envelope is not found during edit", %{conn: conn, workspace: workspace} do
      non_existent_id = Ecto.UUID.generate()
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _workspace_param, _external_id, _opts ->
        {:error, :not_found}
      end)

      render_click(view, "edit_envelope", %{"id" => non_existent_id})

      assert has_element?(view, ".alert-error", "Envelope not found")
    end

    test "shows error when unauthorized to edit envelope", %{
      conn: conn,
      workspace: workspace,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _workspace_param, _external_id, _opts ->
        {:error, :unauthorized}
      end)

      render_click(view, "edit_envelope", %{"id" => envelope.external_id})

      assert has_element?(view, ".alert-error", "You don't have permission to edit this envelope")
    end

    test "correctly resets form when canceling edit", %{
      conn: conn,
      workspace: workspace,
      category: category,
      envelope: envelope
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(Budgeting, :fetch_envelope_by_external_id, fn _scope, _workspace_param, external_id, _opts ->
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
      |> element("button[phx-click='new_envelope'][phx-value-id='#{category.external_id}']")
      |> render_click()

      assert has_element?(view, "h3", "Add New Envelope")
      assert has_element?(view, "button[type='submit']", "Create")
      assert has_element?(view, "form[phx-submit='save_envelope']")
    end
  end

  describe "Envelope Creation" do
    test "opens envelope modal when + button is clicked", %{
      conn: conn,
      workspace: workspace,
      category: category
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      view
      |> element("button[phx-click='new_envelope'][phx-value-id='#{category.external_id}']")
      |> render_click()

      assert has_element?(view, ".modal-open")
      assert has_element?(view, "h3", "Add New Envelope")
      assert has_element?(view, "form[phx-submit='save_envelope']")
      assert has_element?(view, "label", "Envelope Name")
    end

    test "closes envelope modal when cancel button is clicked", %{
      conn: conn,
      workspace: workspace,
      category: category
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      view
      |> element("button[phx-click='new_envelope'][phx-value-id='#{category.external_id}']")
      |> render_click()

      assert has_element?(view, ".modal-open")

      view
      |> element("button", "Cancel")
      |> render_click()

      refute has_element?(view, ".modal-open")
    end

    test "closes envelope modal when clicking backdrop", %{
      conn: conn,
      workspace: workspace,
      category: category
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      view
      |> element("button[phx-click='new_envelope'][phx-value-id='#{category.external_id}']")
      |> render_click()

      assert has_element?(view, ".modal-open")

      view
      |> element(".modal-backdrop")
      |> render_click()

      refute has_element?(view, ".modal-open")
    end

    test "creates a new envelope successfully", %{conn: conn, workspace: workspace, category: category} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      view
      |> element("button[phx-click='new_envelope'][phx-value-id='#{category.external_id}']")
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
      workspace: workspace,
      category: category
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      view
      |> element("button[phx-click='new_envelope'][phx-value-id='#{category.external_id}']")
      |> render_click()

      view
      |> form("#envelope-form", %{envelope: %{name: ""}})
      |> render_submit()

      assert has_element?(view, ".modal-open")
    end

    test "handles unauthorized envelope creation", %{
      conn: conn,
      workspace: workspace,
      category: category
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      view
      |> element("button[phx-click='new_envelope'][phx-value-id='#{category.external_id}']")
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

    test "shows error when category is not found during new_envelope", %{conn: conn, workspace: workspace} do
      non_existent_id = Ecto.UUID.generate()
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(Budgeting, :fetch_category_by_external_id, fn _scope, _workspace, _external_id, _opts ->
        {:error, :not_found}
      end)

      render_click(view, "new_envelope", %{"id" => non_existent_id})

      assert has_element?(view, ".alert-error", "Category not found")
    end

    test "shows error when unauthorized to open envelope modal", %{
      conn: conn,
      workspace: workspace,
      category: category
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(Budgeting, :fetch_category_by_external_id, fn _scope, _workspace, _external_id, _opts ->
        {:error, :unauthorized}
      end)

      render_click(view, "new_envelope", %{"id" => category.external_id})

      assert has_element?(view, ".alert-error", "You don't have permission to access this category")
    end
  end

  describe "Category Repositioning" do
    setup %{workspace: workspace} do
      cat1 = BudgetingFactory.insert(:category, name: "Category 1", workspace_id: workspace.id, position: "ca")
      cat2 = BudgetingFactory.insert(:category, name: "Category 2", workspace_id: workspace.id, position: "cb")
      cat3 = BudgetingFactory.insert(:category, name: "Category 3", workspace_id: workspace.id, position: "cc")

      %{cat1: cat1, cat2: cat2, cat3: cat3}
    end

    test "successfully repositions category between two others", %{
      conn: conn,
      workspace: workspace,
      cat1: cat1,
      cat2: cat2,
      cat3: cat3
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(RepositionCategory, :call, fn _scope, _category_id, _prev_id, _next_id ->
        {:ok, cat3}
      end)

      # Move cat3 between cat1 and cat2
      result =
        view
        |> element("#categories")
        |> render_hook("reposition_category", %{
          "category_id" => cat3.external_id,
          "prev_category_id" => cat1.external_id,
          "next_category_id" => cat2.external_id
        })

      assert result =~ "success"
    end

    test "successfully repositions category to the beginning", %{conn: conn, workspace: workspace, cat2: cat2, cat3: cat3} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(RepositionCategory, :call, fn _scope, _category_id, _prev_id, _next_id ->
        {:ok, cat3}
      end)

      # Move cat3 to the beginning
      result =
        view
        |> element("#categories")
        |> render_hook("reposition_category", %{
          "category_id" => cat3.external_id,
          "prev_category_id" => nil,
          "next_category_id" => cat2.external_id
        })

      assert result =~ "success"
    end

    test "successfully repositions category to the end", %{conn: conn, workspace: workspace, cat1: cat1, cat3: cat3} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(RepositionCategory, :call, fn _scope, _category_id, _prev_id, _next_id ->
        {:ok, cat1}
      end)

      # Move cat1 to the end
      result =
        view
        |> element("#categories")
        |> render_hook("reposition_category", %{
          "category_id" => cat1.external_id,
          "prev_category_id" => cat3.external_id,
          "next_category_id" => nil
        })

      assert result =~ "success"
    end

    test "handles unauthorized category repositioning", %{conn: conn, workspace: workspace, cat1: cat1, cat2: cat2} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(RepositionCategory, :call, fn _scope, _category_id, _prev_id, _next_id ->
        {:error, :unauthorized}
      end)

      view
      |> element("#categories")
      |> render_hook("reposition_category", %{
        "category_id" => cat1.external_id,
        "prev_category_id" => nil,
        "next_category_id" => cat2.external_id
      })

      assert has_element?(view, ".alert-error", "You don't have permission to reposition categories")
    end

    test "handles category not found error", %{conn: conn, workspace: workspace} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")
      non_existent_id = Ecto.UUID.generate()

      stub(RepositionCategory, :call, fn _scope, _category_id, _prev_id, _next_id ->
        {:error, :not_found}
      end)

      view
      |> element("#categories")
      |> render_hook("reposition_category", %{
        "category_id" => non_existent_id,
        "prev_category_id" => nil,
        "next_category_id" => nil
      })

      assert has_element?(view, ".alert-error", "Category not found")
    end

    test "handles general repositioning error", %{conn: conn, workspace: workspace, cat1: cat1} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(RepositionCategory, :call, fn _scope, _category_id, _prev_id, _next_id ->
        {:error, :database_error}
      end)

      view
      |> element("#categories")
      |> render_hook("reposition_category", %{
        "category_id" => cat1.external_id,
        "prev_category_id" => nil,
        "next_category_id" => nil
      })

      assert has_element?(view, ".alert-error", "Failed to save category position. Please try again.")
    end

    test "refreshes categories on category_repositioned event", %{conn: conn, workspace: workspace, cat1: cat1} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      new_category = BudgetingFactory.insert(:category, name: "New Category", workspace_id: workspace.id, position: "zz")
      new_category_with_envelopes = %{new_category | envelopes: []}

      stub(Budgeting, :list_categories, fn _scope, _workspace, _opts ->
        [new_category_with_envelopes]
      end)

      send(view.pid, {:category_repositioned, cat1})

      assert has_element?(view, "h3", "New Category")
    end
  end

  describe "Error handling" do
    test "redirects to workspaces page when workspace doesn't exist with not_found error", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()

      stub(PurseCraft.Core.Policy, :authorize, fn :workspace_read, _scope, _workspace ->
        :ok
      end)

      assert {:error, {:live_redirect, %{to: "/workspaces", flash: %{"error" => "Workspace not found"}}}} =
               live(conn, ~p"/workspaces/#{non_existent_id}/budget")
    end

    test "redirects to workspaces page when workspace doesn't exist", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()

      assert {:error,
              {:live_redirect, %{to: "/workspaces", flash: %{"error" => "You don't have access to this workspace"}}}} =
               live(conn, ~p"/workspaces/#{non_existent_id}/budget")
    end

    test "redirects to workspaces page when unauthorized", %{conn: conn} do
      workspace = CoreFactory.insert(:workspace, name: "Someone Else's Budget")

      assert {:error,
              {:live_redirect, %{to: "/workspaces", flash: %{"error" => "You don't have access to this workspace"}}}} =
               live(conn, ~p"/workspaces/#{workspace.external_id}/budget")
    end

    test "redirects when categories access is unauthorized", %{conn: conn, workspace: workspace} do
      stub(FetchWorkspaceByExternalId, :call, fn _scope, _external_id ->
        {:ok, workspace}
      end)

      stub(Budgeting, :list_categories, fn _scope, _workspace, _opts ->
        {:error, :unauthorized}
      end)

      assert {:error,
              {:live_redirect,
               %{to: "/workspaces", flash: %{"error" => "You don't have access to this workspace's categories"}}}} =
               live(conn, ~p"/workspaces/#{workspace.external_id}/budget")
    end
  end

  describe "Envelope Repositioning" do
    setup %{workspace: workspace} do
      category1 = BudgetingFactory.insert(:category, name: "Housing", workspace_id: workspace.id, position: "ea")
      category2 = BudgetingFactory.insert(:category, name: "Transportation", workspace_id: workspace.id, position: "eb")

      env1 = BudgetingFactory.insert(:envelope, name: "Rent", category_id: category1.id, position: "ed")
      env2 = BudgetingFactory.insert(:envelope, name: "Utilities", category_id: category1.id, position: "eh")
      env3 = BudgetingFactory.insert(:envelope, name: "Insurance", category_id: category1.id, position: "ep")

      %{
        category1: %{category1 | envelopes: [env1, env2, env3]},
        category2: %{category2 | envelopes: []},
        env1: env1,
        env2: env2,
        env3: env3
      }
    end

    test "successfully repositions envelope within same category", %{
      conn: conn,
      workspace: workspace,
      category1: category1,
      env1: env1,
      env2: env2,
      env3: env3
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(RepositionEnvelope, :call, fn _scope, _envelope_id, _target_category_id, _prev_id, _next_id ->
        {:ok, env3}
      end)

      # Move env3 between env1 and env2
      result =
        view
        |> element("#categories")
        |> render_hook("reposition_envelope", %{
          "envelope_id" => env3.external_id,
          "target_category_id" => category1.external_id,
          "prev_envelope_id" => env1.external_id,
          "next_envelope_id" => env2.external_id
        })

      assert result =~ "success"
    end

    test "successfully repositions envelope to different category", %{
      conn: conn,
      workspace: workspace,
      category2: category2,
      env1: env1
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(RepositionEnvelope, :call, fn _scope, _envelope_id, _target_category_id, _prev_id, _next_id ->
        {:ok, env1}
      end)

      # Move env1 to category2
      result =
        view
        |> element("#categories")
        |> render_hook("reposition_envelope", %{
          "envelope_id" => env1.external_id,
          "target_category_id" => category2.external_id,
          "prev_envelope_id" => nil,
          "next_envelope_id" => nil
        })

      assert result =~ "success"
    end

    test "handles unauthorized envelope repositioning", %{
      conn: conn,
      workspace: workspace,
      category1: category1,
      env1: env1,
      env2: env2
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(RepositionEnvelope, :call, fn _scope, _envelope_id, _target_category_id, _prev_id, _next_id ->
        {:error, :unauthorized}
      end)

      view
      |> element("#categories")
      |> render_hook("reposition_envelope", %{
        "envelope_id" => env1.external_id,
        "target_category_id" => category1.external_id,
        "prev_envelope_id" => nil,
        "next_envelope_id" => env2.external_id
      })

      assert has_element?(view, ".alert-error", "You don't have permission to reposition envelopes")
    end

    test "handles envelope not found error", %{
      conn: conn,
      workspace: workspace,
      category1: category1
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")
      non_existent_id = Ecto.UUID.generate()

      stub(RepositionEnvelope, :call, fn _scope, _envelope_id, _target_category_id, _prev_id, _next_id ->
        {:error, :not_found}
      end)

      view
      |> element("#categories")
      |> render_hook("reposition_envelope", %{
        "envelope_id" => non_existent_id,
        "target_category_id" => category1.external_id,
        "prev_envelope_id" => nil,
        "next_envelope_id" => nil
      })

      assert has_element?(view, ".alert-error", "Envelope or category not found")
    end

    test "handles general repositioning error", %{
      conn: conn,
      workspace: workspace,
      category1: category1,
      env1: env1
    } do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      stub(RepositionEnvelope, :call, fn _scope, _envelope_id, _target_category_id, _prev_id, _next_id ->
        {:error, :database_error}
      end)

      view
      |> element("#categories")
      |> render_hook("reposition_envelope", %{
        "envelope_id" => env1.external_id,
        "target_category_id" => category1.external_id,
        "prev_envelope_id" => nil,
        "next_envelope_id" => nil
      })

      assert has_element?(view, ".alert-error", "Failed to save envelope position. Please try again.")
    end
  end

  describe "Envelope PubSub Events" do
    test "handles envelope_repositioned message with successful category fetch", %{
      conn: conn,
      workspace: workspace
    } do
      category = BudgetingFactory.insert(:category, name: "Housing", workspace_id: workspace.id, position: "aa")
      envelope1 = BudgetingFactory.insert(:envelope, name: "Rent", category_id: category.id, position: "a")
      envelope2 = BudgetingFactory.insert(:envelope, name: "Utilities", category_id: category.id, position: "b")

      {:ok, view, html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      assert html =~ "Housing"
      assert html =~ "Rent"
      assert html =~ "Utilities"

      updated_envelope1 = %{envelope1 | position: "b"}
      updated_envelope2 = %{envelope2 | position: "a"}
      updated_category = %{category | envelopes: [updated_envelope2, updated_envelope1]}

      stub(CategoryRepository, :fetch, fn category_id, _opts ->
        if category_id == category.id do
          {:ok, updated_category}
        else
          {:error, :not_found}
        end
      end)

      send(view.pid, {:envelope_repositioned, %{category_id: category.id}})

      updated_html = render(view)
      assert updated_html =~ "Housing"
      assert updated_html =~ "Rent"
      assert updated_html =~ "Utilities"
    end

    test "handles envelope_repositioned message with category not found", %{
      conn: conn,
      workspace: workspace
    } do
      category = BudgetingFactory.insert(:category, name: "Housing", workspace_id: workspace.id, position: "ab")
      BudgetingFactory.insert(:envelope, name: "Rent", category_id: category.id)

      {:ok, view, html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      assert html =~ "Housing"
      assert html =~ "Rent"

      stub(CategoryRepository, :fetch, fn _category_id, _opts ->
        {:error, :not_found}
      end)

      send(view.pid, {:envelope_repositioned, %{category_id: category.id}})

      updated_html = render(view)
      assert updated_html =~ "Housing"
      assert updated_html =~ "Rent"
    end

    test "handles envelope_removed message with successful category fetch", %{
      conn: conn,
      workspace: workspace
    } do
      category = BudgetingFactory.insert(:category, name: "Housing", workspace_id: workspace.id, position: "ac")
      envelope1 = BudgetingFactory.insert(:envelope, name: "Rent", category_id: category.id)
      BudgetingFactory.insert(:envelope, name: "Utilities", category_id: category.id)

      {:ok, view, html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      assert html =~ "Housing"
      assert html =~ "Rent"
      assert html =~ "Utilities"

      updated_category = %{category | envelopes: [envelope1]}

      stub(CategoryRepository, :fetch, fn category_id, _opts ->
        if category_id == category.id do
          {:ok, updated_category}
        else
          {:error, :not_found}
        end
      end)

      send(view.pid, {:envelope_removed, %{category_id: category.id}})

      updated_html = render(view)
      assert updated_html =~ "Housing"
      assert updated_html =~ "Rent"
      refute updated_html =~ "Utilities"
    end

    test "handles envelope_removed message with category not found", %{
      conn: conn,
      workspace: workspace
    } do
      category = BudgetingFactory.insert(:category, name: "Housing", workspace_id: workspace.id, position: "ad")
      BudgetingFactory.insert(:envelope, name: "Rent", category_id: category.id)

      {:ok, view, html} = live(conn, ~p"/workspaces/#{workspace.external_id}/budget")

      assert html =~ "Housing"
      assert html =~ "Rent"

      stub(CategoryRepository, :fetch, fn _category_id, _opts ->
        {:error, :not_found}
      end)

      send(view.pid, {:envelope_removed, %{category_id: category.id}})

      updated_html = render(view)
      assert updated_html =~ "Housing"
      assert updated_html =~ "Rent"
    end
  end
end
