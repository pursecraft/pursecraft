defmodule PurseCraftWeb.BudgetLive.Index do
  @moduledoc false

  use PurseCraftWeb, :live_view

  alias PurseCraft.Accounting
  alias PurseCraft.Budgeting
  alias PurseCraft.PubSub
  alias PurseCraft.Budgeting.Commands.Categories.RepositionCategory
  alias PurseCraft.Budgeting.Commands.Envelopes.RepositionEnvelope
  alias PurseCraft.Budgeting.Repositories.CategoryRepository
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
            Budgeting.subscribe_book(book)
            subscribe_to_categories(categories)

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
              |> assign(:envelope_modal_action, "save_envelope")
              |> assign(:envelope_modal_button, "Create")
              |> assign(:modal_title, "Add New Category")
              |> assign(:modal_action, "save_category")
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
  def handle_event("new_category", _params, socket) do
    {:noreply, show_category_modal(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("cancel_category", _params, socket) do
    {:noreply, hide_category_modal(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("cancel_category_form", _params, socket) do
    {:noreply, hide_category_modal(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("edit_category", %{"id" => external_id}, socket) do
    socket.assigns.current_scope
    |> Budgeting.fetch_category_by_external_id(socket.assigns.book, external_id)
    |> case do
      {:ok, category} ->
        {:noreply, show_category_modal(socket, category)}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Category not found")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You don't have permission to edit this category")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("save_category", %{"category" => category_params}, socket) do
    category = socket.assigns.editing_category

    if category && category.id do
      handle_category_update(socket, category, category_params)
    else
      handle_category_create(socket, category_params)
    end
  end

  @impl Phoenix.LiveView
  def handle_event("delete_category_confirm", %{"id" => external_id}, socket) do
    socket.assigns.current_scope
    |> Budgeting.fetch_category_by_external_id(socket.assigns.book, external_id, preload: [:envelopes])
    |> case do
      {:ok, category} ->
        if Enum.empty?(category.envelopes) do
          {:noreply, show_delete_modal(socket, category, :category)}
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
  def handle_event("cancel_delete", _params, socket) do
    {:noreply, hide_delete_modal(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("delete_category", %{"id" => _external_id}, socket) do
    category = socket.assigns.category_to_delete

    socket.assigns.current_scope
    |> Budgeting.delete_category(socket.assigns.book, category)
    |> case do
      {:ok, deleted_category} ->
        socket =
          socket
          |> stream_delete(:categories, deleted_category)
          |> hide_delete_modal()
          |> put_flash(:info, "Category deleted successfully")

        {:noreply, socket}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You don't have permission to delete this category")
         |> hide_delete_modal()}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error deleting category")
         |> hide_delete_modal()}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("new_envelope", %{"id" => external_id}, socket) do
    socket.assigns.current_scope
    |> Budgeting.fetch_category_by_external_id(socket.assigns.book, external_id, preload: [:envelopes])
    |> case do
      {:ok, category} ->
        {:noreply, show_envelope_modal(socket, %Envelope{}, category)}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Category not found")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You don't have permission to access this category")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("cancel_envelope", _params, socket) do
    {:noreply, hide_envelope_modal(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("cancel_envelope_form", _params, socket) do
    {:noreply, hide_envelope_modal(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("save_envelope", %{"envelope" => envelope_params}, socket) do
    envelope = socket.assigns.editing_envelope
    category = socket.assigns.selected_category_for_envelope

    if envelope && envelope.id do
      socket.assigns.current_scope
      |> Budgeting.update_envelope(socket.assigns.book, envelope, envelope_params)
      |> case do
        {:ok, updated_envelope} ->
          handle_successful_envelope_update(socket, category, updated_envelope)

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, :envelope_form, to_form(changeset))}

        {:error, :unauthorized} ->
          {:noreply,
           socket
           |> put_flash(:error, "You don't have permission to update envelopes")
           |> hide_envelope_modal()}
      end
    else
      socket.assigns.current_scope
      |> Budgeting.create_envelope(socket.assigns.book, category, envelope_params)
      |> case do
        {:ok, envelope} ->
          updated_category = %{
            category
            | envelopes: [envelope | category.envelopes]
          }

          socket =
            socket
            |> stream_insert(:categories, updated_category)
            |> hide_envelope_modal()
            |> put_flash(:info, "Envelope created successfully")

          {:noreply, socket}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, :envelope_form, to_form(changeset))}

        {:error, :unauthorized} ->
          {:noreply,
           socket
           |> put_flash(:error, "You don't have permission to create envelopes")
           |> hide_envelope_modal()}
      end
    end
  end

  @impl Phoenix.LiveView
  def handle_event("edit_envelope", %{"id" => external_id}, socket) do
    socket.assigns.current_scope
    |> Budgeting.fetch_envelope_by_external_id(socket.assigns.book, external_id, preload: [category: [:envelopes]])
    |> case do
      {:ok, envelope} ->
        {:noreply, show_envelope_modal(socket, envelope, envelope.category)}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Envelope not found")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You don't have permission to edit this envelope")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("delete_envelope_confirm", %{"id" => external_id}, socket) do
    socket.assigns.current_scope
    |> Budgeting.fetch_envelope_by_external_id(socket.assigns.book, external_id, preload: [category: [:envelopes]])
    |> case do
      {:ok, envelope} ->
        {:noreply, show_delete_modal(socket, envelope, :envelope)}

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

    socket.assigns.current_scope
    |> Budgeting.delete_envelope(socket.assigns.book, envelope)
    |> case do
      {:ok, deleted_envelope} ->
        updated_envelopes = Enum.reject(category.envelopes, fn e -> e.id == deleted_envelope.id end)
        updated_category = %{category | envelopes: updated_envelopes}

        socket =
          socket
          |> stream_insert(:categories, updated_category)
          |> hide_envelope_modal()
          |> hide_delete_modal()
          |> put_flash(:info, "Envelope deleted successfully")

        {:noreply, socket}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You don't have permission to delete this envelope")
         |> hide_envelope_modal()
         |> hide_delete_modal()}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error deleting envelope")
         |> hide_envelope_modal()
         |> hide_delete_modal()}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("reposition_envelope", params, socket) do
    envelope_id = params["envelope_id"]
    target_category_id = params["target_category_id"]
    prev_envelope_id = params["prev_envelope_id"]
    next_envelope_id = params["next_envelope_id"]

    case RepositionEnvelope.call(
           socket.assigns.current_scope,
           envelope_id,
           target_category_id,
           prev_envelope_id,
           next_envelope_id
         ) do
      {:ok, _updated_envelope} ->
        {:reply, %{success: true}, socket}

      {:error, :unauthorized} ->
        {:reply, %{error: "You don't have permission to reposition envelopes"},
         put_flash(socket, :error, "You don't have permission to reposition envelopes")}

      {:error, :not_found} ->
        {:reply, %{error: "Envelope or category not found"}, put_flash(socket, :error, "Envelope or category not found")}

      {:error, _reason} ->
        {:reply, %{error: "Failed to save position"},
         put_flash(socket, :error, "Failed to save envelope position. Please try again.")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("reposition_category", params, socket) do
    category_id = params["category_id"]
    prev_category_id = params["prev_category_id"]
    next_category_id = params["next_category_id"]

    case RepositionCategory.call(
           socket.assigns.current_scope,
           category_id,
           prev_category_id,
           next_category_id
         ) do
      {:ok, _updated_category} ->
        {:reply, %{success: true}, socket}

      {:error, :unauthorized} ->
        {:reply, %{error: "You don't have permission to reposition categories"},
         put_flash(socket, :error, "You don't have permission to reposition categories")}

      {:error, :not_found} ->
        {:reply, %{error: "Category not found"}, put_flash(socket, :error, "Category not found")}

      {:error, _reason} ->
        {:reply, %{error: "Failed to save position"},
         put_flash(socket, :error, "Failed to save category position. Please try again.")}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:category_repositioned, _category}, socket) do
    categories =
      Budgeting.list_categories(socket.assigns.current_scope, socket.assigns.book, preload: [:envelopes])

    {:noreply, stream(socket, :categories, categories, reset: true)}
  end

  @impl Phoenix.LiveView
  def handle_info({:envelope_repositioned, %{category_id: category_id}}, socket) do
    case CategoryRepository.fetch(category_id, preload: [:envelopes]) do
      {:ok, updated_category} ->
        {:noreply, stream_insert(socket, :categories, updated_category)}

      {:error, :not_found} ->
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:envelope_removed, %{category_id: category_id}}, socket) do
    case CategoryRepository.fetch(category_id, preload: [:envelopes]) do
      {:ok, updated_category} ->
        {:noreply, stream_insert(socket, :categories, updated_category)}

      {:error, :not_found} ->
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({_event, _data}, socket) do
    {:noreply, socket}
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
      |> hide_envelope_modal()
      |> put_flash(:info, "Envelope updated successfully")

    {:noreply, socket}
  end

  defp show_category_modal(socket, category \\ %Category{}) do
    {title, action, button} =
      if category.id do
        {"Edit Category", "save_category", "Update"}
      else
        {"Add New Category", "save_category", "Create"}
      end

    socket
    |> assign(:editing_category, category)
    |> assign(:category_form, to_form(Budgeting.change_category(category)))
    |> assign(:modal_title, title)
    |> assign(:modal_action, action)
    |> assign(:modal_button, button)
    |> assign(:category_modal_open, true)
  end

  defp hide_category_modal(socket) do
    socket
    |> assign(:category_modal_open, false)
    |> assign(:editing_category, nil)
    |> assign(:category_form, to_form(Budgeting.change_category(%Category{})))
    |> assign(:modal_title, "Add New Category")
    |> assign(:modal_action, "save_category")
    |> assign(:modal_button, "Create")
  end

  defp show_envelope_modal(socket, envelope, category) do
    {title, action, button} =
      if envelope.id do
        {"Edit Envelope", "save_envelope", "Update"}
      else
        {"Add New Envelope", "save_envelope", "Create"}
      end

    socket
    |> assign(:editing_envelope, envelope)
    |> assign(:selected_category_for_envelope, category)
    |> assign(:envelope_form, to_form(Budgeting.change_envelope(envelope)))
    |> assign(:envelope_modal_title, title)
    |> assign(:envelope_modal_action, action)
    |> assign(:envelope_modal_button, button)
    |> assign(:envelope_modal_open, true)
  end

  defp hide_envelope_modal(socket) do
    socket
    |> assign(:envelope_modal_open, false)
    |> assign(:editing_envelope, nil)
    |> assign(:selected_category_for_envelope, nil)
    |> assign(:envelope_form, to_form(Budgeting.change_envelope(%Envelope{})))
    |> assign(:envelope_modal_title, "Add New Envelope")
    |> assign(:envelope_modal_action, "save_envelope")
    |> assign(:envelope_modal_button, "Create")
  end

  defp show_delete_modal(socket, item, type) do
    case type do
      :category ->
        socket
        |> assign(:category_to_delete, item)
        |> assign(:delete_modal_open, true)

      :envelope ->
        socket
        |> assign(:envelope_to_delete, item)
        |> assign(:selected_category_for_envelope, item.category)
        |> assign(:envelope_modal_title, "Delete Envelope")
        |> assign(:envelope_modal_action, "delete-envelope")
        |> assign(:envelope_modal_open, true)
    end
  end

  defp hide_delete_modal(socket) do
    socket
    |> assign(:delete_modal_open, false)
    |> assign(:category_to_delete, nil)
    |> assign(:envelope_to_delete, nil)
    |> assign(:selected_category_for_envelope, nil)
  end

  defp handle_category_update(socket, category, category_params) do
    socket.assigns.current_scope
    |> Budgeting.update_category(socket.assigns.book, category, category_params, preload: [:envelopes])
    |> handle_category_result(socket, "Category updated successfully")
  end

  defp handle_category_create(socket, category_params) do
    socket.assigns.current_scope
    |> Budgeting.create_category(socket.assigns.book, category_params)
    |> handle_category_result(socket, "Category created successfully", at: 0)
  end

  defp handle_category_result(result, socket, success_message, opts \\ [])

  defp handle_category_result({:ok, category}, socket, success_message, opts) do
    category = if opts[:at] == 0, do: %{category | envelopes: []}, else: category
    stream_opts = if opts[:at], do: [at: opts[:at]], else: []

    socket =
      socket
      |> stream_insert(:categories, category, stream_opts)
      |> hide_category_modal()
      |> put_flash(:info, success_message)

    {:noreply, socket}
  end

  defp handle_category_result({:error, %Ecto.Changeset{} = changeset}, socket, _success_message, _opts) do
    {:noreply, assign(socket, :category_form, to_form(changeset))}
  end

  defp handle_category_result({:error, :unauthorized}, socket, _success_message, _opts) do
    error_message =
      if socket.assigns.editing_category && socket.assigns.editing_category.id do
        "You don't have permission to update categories"
      else
        "You don't have permission to create categories"
      end

    {:noreply,
     socket
     |> put_flash(:error, error_message)
     |> hide_category_modal()}
  end

  # coveralls-ignore-start
  defp handle_category_result({:error, _message}, socket, _success_message, _opts) do
    {:noreply,
     socket
     |> put_flash(:error, "Unable to create category")
     |> hide_category_modal()}
  end

  # coveralls-ignore-stop

  defp subscribe_to_categories(categories) do
    Enum.each(categories, fn category ->
      PubSub.subscribe_category(category.external_id)
    end)
  end
end
