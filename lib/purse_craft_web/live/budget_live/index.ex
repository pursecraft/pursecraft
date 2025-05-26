defmodule PurseCraftWeb.BudgetLive.Index do
  @moduledoc false

  use PurseCraftWeb, :live_view

  alias PurseCraft.Budgeting
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraftWeb.BudgetLive.Components.BudgetHeader
  alias PurseCraftWeb.BudgetLive.Components.CategorySection
  alias PurseCraftWeb.BudgetLive.Components.EnvelopeRow
  alias PurseCraftWeb.Components.UI.Budgeting.Button
  alias PurseCraftWeb.Components.UI.Budgeting.Card
  alias PurseCraftWeb.Components.UI.Budgeting.Form
  alias PurseCraftWeb.Components.UI.Budgeting.Modal

  @impl Phoenix.LiveView
  def mount(%{"external_id" => external_id}, _session, socket) do
    case Budgeting.fetch_book_by_external_id(socket.assigns.current_scope, external_id) do
      {:ok, book} ->
        case Budgeting.list_categories(socket.assigns.current_scope, book, preload: [:envelopes]) do
          {:error, :unauthorized} ->
            {:ok,
             socket
             |> put_flash(:error, "You don't have access to this book's categories")
             |> push_navigate(to: ~p"/books")}

          categories ->
            socket =
              socket
              |> assign(:page_title, "Budget - #{book.name}")
              |> assign(:current_path, "/books/#{book.external_id}/budget")
              |> assign(:book, book)
              |> assign(:category_form, to_form(Budgeting.change_category(%Category{})))
              |> assign(
                :envelope_form,
                to_form(Budgeting.change_envelope(%Envelope{}))
              )
              |> assign(:category_modal_open, false)
              |> assign(:envelope_modal_open, false)
              |> assign(:delete_modal_open, false)
              |> assign(:editing_category, nil)
              |> assign(:editing_envelope, nil)
              |> assign(:category_to_delete, nil)
              |> assign(:envelope_to_delete, nil)
              |> assign(:selected_category_for_envelope, nil)
              |> assign(:envelope_modal_title, "Add New Envelope")
              |> assign(:envelope_modal_action, "create-envelope")
              |> assign(:envelope_modal_button, "Create")
              |> assign(:modal_title, "Add New Category")
              |> assign(:modal_action, "create-category")
              |> assign(:modal_button, "Create")
              |> stream_configure(:categories, dom_id: &"categories-#{&1.external_id}")
              |> stream(:categories, categories)

            {:ok, socket}
        end

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Book not found")
         |> push_navigate(to: ~p"/books")}

      {:error, :unauthorized} ->
        {:ok,
         socket
         |> put_flash(:error, "You don't have access to this book")
         |> push_navigate(to: ~p"/books")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("open_category_modal", _params, socket) do
    {:noreply, assign(socket, :category_modal_open, true)}
  end

  @impl Phoenix.LiveView
  def handle_event("close_category_modal", _params, socket) do
    {:noreply, assign(socket, :category_modal_open, false)}
  end

  @impl Phoenix.LiveView
  def handle_event("reset-category-form", _params, socket) do
    {:noreply,
     socket
     |> assign(:category_form, to_form(Budgeting.change_category(%Category{})))
     |> assign(:editing_category, nil)
     |> assign(:modal_title, "Add New Category")
     |> assign(:modal_action, "create-category")
     |> assign(:modal_button, "Create")
     |> assign(:category_modal_open, false)}
  end

  @impl Phoenix.LiveView
  def handle_event("edit_category", %{"id" => external_id}, socket) do
    case Budgeting.fetch_category_by_external_id(socket.assigns.current_scope, socket.assigns.book, external_id) do
      {:ok, category} ->
        socket =
          socket
          |> assign(:editing_category, category)
          |> assign(:category_form, to_form(Budgeting.change_category(category)))
          |> assign(:modal_title, "Edit Category")
          |> assign(:modal_action, "update-category")
          |> assign(:modal_button, "Update")
          |> assign(:category_modal_open, true)

        {:noreply, socket}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Category not found")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You don't have permission to edit this category")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("create-category", %{"category" => category_params}, socket) do
    case Budgeting.create_category(socket.assigns.current_scope, socket.assigns.book, category_params) do
      {:ok, category} ->
        category = %{category | envelopes: []}

        socket =
          socket
          |> stream_insert(:categories, category, at: 0)
          |> assign(:category_modal_open, false)
          |> put_flash(:info, "Category created successfully")
          |> assign(:category_form, to_form(Budgeting.change_category(%Category{})))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :category_form, to_form(changeset))}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You don't have permission to create categories")
         |> assign(:category_modal_open, false)}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("update-category", %{"category" => category_params}, socket) do
    category = socket.assigns.editing_category

    case Budgeting.update_category(socket.assigns.current_scope, socket.assigns.book, category, category_params,
           preload: [:envelopes]
         ) do
      {:ok, updated_category} ->
        socket =
          socket
          |> stream_insert(:categories, updated_category)
          |> assign(:category_modal_open, false)
          |> assign(:editing_category, nil)
          |> put_flash(:info, "Category updated successfully")
          |> assign(:category_form, to_form(Budgeting.change_category(%Category{})))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :category_form, to_form(changeset))}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You don't have permission to update categories")
         |> assign(:category_modal_open, false)
         |> assign(:editing_category, nil)}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("open_delete_modal", %{"id" => external_id}, socket) do
    case Budgeting.fetch_category_by_external_id(socket.assigns.current_scope, socket.assigns.book, external_id,
           preload: [:envelopes]
         ) do
      {:ok, category} ->
        if Enum.empty?(category.envelopes) do
          {:noreply,
           socket
           |> assign(:category_to_delete, category)
           |> assign(:delete_modal_open, true)}
        else
          {:noreply, put_flash(socket, :error, "Cannot delete a category with envelopes")}
        end

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Category not found")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You don't have permission to delete this category")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("close_delete_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:delete_modal_open, false)
     |> assign(:category_to_delete, nil)}
  end

  @impl Phoenix.LiveView
  def handle_event("delete_category", %{"id" => _external_id}, socket) do
    category = socket.assigns.category_to_delete

    case Budgeting.delete_category(socket.assigns.current_scope, socket.assigns.book, category) do
      {:ok, deleted_category} ->
        socket =
          socket
          |> stream_delete(:categories, deleted_category)
          |> assign(:delete_modal_open, false)
          |> assign(:category_to_delete, nil)
          |> put_flash(:info, "Category deleted successfully")

        {:noreply, socket}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You don't have permission to delete this category")
         |> assign(:delete_modal_open, false)
         |> assign(:category_to_delete, nil)}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error deleting category")
         |> assign(:delete_modal_open, false)
         |> assign(:category_to_delete, nil)}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("open_envelope_modal", %{"id" => external_id}, socket) do
    case Budgeting.fetch_category_by_external_id(socket.assigns.current_scope, socket.assigns.book, external_id,
           preload: [:envelopes]
         ) do
      {:ok, category} ->
        {:noreply,
         socket
         |> assign(:selected_category_for_envelope, category)
         |> assign(:envelope_form, to_form(Budgeting.change_envelope(%Envelope{})))
         |> assign(:envelope_modal_title, "Add New Envelope")
         |> assign(:envelope_modal_action, "create-envelope")
         |> assign(:envelope_modal_button, "Create")
         |> assign(:envelope_modal_open, true)}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Category not found")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You don't have permission to access this category")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("close_envelope_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:envelope_modal_open, false)
     |> assign(:selected_category_for_envelope, nil)
     |> assign(:editing_envelope, nil)
     |> assign(:envelope_form, to_form(Budgeting.change_envelope(%Envelope{})))}
  end

  @impl Phoenix.LiveView
  def handle_event("reset-envelope-form", _params, socket) do
    {:noreply,
     socket
     |> assign(:envelope_form, to_form(Budgeting.change_envelope(%Envelope{})))
     |> assign(:editing_envelope, nil)
     |> assign(:selected_category_for_envelope, nil)
     |> assign(:envelope_modal_title, "Add New Envelope")
     |> assign(:envelope_modal_action, "create-envelope")
     |> assign(:envelope_modal_button, "Create")
     |> assign(:envelope_modal_open, false)}
  end

  @impl Phoenix.LiveView
  def handle_event("create-envelope", %{"envelope" => envelope_params}, socket) do
    category = socket.assigns.selected_category_for_envelope

    case Budgeting.create_envelope(
           socket.assigns.current_scope,
           socket.assigns.book,
           category,
           envelope_params
         ) do
      {:ok, envelope} ->
        updated_category = %{
          category
          | envelopes: [envelope | category.envelopes]
        }

        socket =
          socket
          |> stream_insert(:categories, updated_category)
          |> assign(:envelope_modal_open, false)
          |> assign(:selected_category_for_envelope, nil)
          |> assign(:envelope_form, to_form(Budgeting.change_envelope(%Envelope{})))
          |> put_flash(:info, "Envelope created successfully")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :envelope_form, to_form(changeset))}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You don't have permission to create envelopes")
         |> assign(:envelope_modal_open, false)
         |> assign(:selected_category_for_envelope, nil)}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("edit_envelope", %{"id" => external_id}, socket) do
    case Budgeting.fetch_envelope_by_external_id(
           socket.assigns.current_scope,
           socket.assigns.book,
           external_id,
           preload: [category: [:envelopes]]
         ) do
      {:ok, envelope} ->
        socket =
          socket
          |> assign(:editing_envelope, envelope)
          |> assign(:selected_category_for_envelope, envelope.category)
          |> assign(:envelope_form, to_form(Budgeting.change_envelope(envelope)))
          |> assign(:envelope_modal_title, "Edit Envelope")
          |> assign(:envelope_modal_action, "update-envelope")
          |> assign(:envelope_modal_button, "Update")
          |> assign(:envelope_modal_open, true)

        {:noreply, socket}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Envelope not found")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You don't have permission to edit this envelope")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("update-envelope", %{"envelope" => envelope_params}, socket) do
    envelope = socket.assigns.editing_envelope
    category = socket.assigns.selected_category_for_envelope

    case Budgeting.update_envelope(socket.assigns.current_scope, socket.assigns.book, envelope, envelope_params) do
      {:ok, updated_envelope} ->
        handle_successful_envelope_update(socket, category, updated_envelope)

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :envelope_form, to_form(changeset))}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You don't have permission to update envelopes")
         |> assign(:envelope_modal_open, false)
         |> assign(:editing_envelope, nil)
         |> assign(:selected_category_for_envelope, nil)}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("open_delete_envelope_modal", %{"id" => external_id}, socket) do
    case Budgeting.fetch_envelope_by_external_id(
           socket.assigns.current_scope,
           socket.assigns.book,
           external_id,
           preload: [category: [:envelopes]]
         ) do
      {:ok, envelope} ->
        {:noreply,
         socket
         |> assign(:envelope_to_delete, envelope)
         |> assign(:selected_category_for_envelope, envelope.category)
         |> assign(:envelope_modal_title, "Delete Envelope")
         |> assign(:envelope_modal_action, "delete-envelope")
         |> assign(:envelope_modal_open, true)}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Envelope not found")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You don't have permission to delete this envelope")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("delete_envelope", %{"id" => _external_id}, socket) do
    envelope = socket.assigns.envelope_to_delete
    category = socket.assigns.selected_category_for_envelope

    case Budgeting.delete_envelope(socket.assigns.current_scope, socket.assigns.book, envelope) do
      {:ok, deleted_envelope} ->
        updated_envelopes = Enum.reject(category.envelopes, fn e -> e.id == deleted_envelope.id end)
        updated_category = %{category | envelopes: updated_envelopes}

        socket =
          socket
          |> stream_insert(:categories, updated_category)
          |> assign(:envelope_modal_open, false)
          |> assign(:envelope_to_delete, nil)
          |> assign(:selected_category_for_envelope, nil)
          |> put_flash(:info, "Envelope deleted successfully")

        {:noreply, socket}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You don't have permission to delete this envelope")
         |> assign(:envelope_modal_open, false)
         |> assign(:envelope_to_delete, nil)
         |> assign(:selected_category_for_envelope, nil)}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error deleting envelope")
         |> assign(:envelope_modal_open, false)
         |> assign(:envelope_to_delete, nil)
         |> assign(:selected_category_for_envelope, nil)}
    end
  end

  defp handle_successful_envelope_update(socket, category, updated_envelope) do
    updated_envelopes =
      Enum.map(category.envelopes, fn e ->
        if e.id == updated_envelope.id, do: updated_envelope, else: e
      end)

    updated_category = %{category | envelopes: updated_envelopes}

    socket =
      socket
      |> stream_insert(:categories, updated_category)
      |> assign(:envelope_modal_open, false)
      |> assign(:editing_envelope, nil)
      |> assign(:selected_category_for_envelope, nil)
      |> put_flash(:info, "Envelope updated successfully")
      |> assign(:envelope_form, to_form(Budgeting.change_envelope(%Envelope{})))

    {:noreply, socket}
  end
end
