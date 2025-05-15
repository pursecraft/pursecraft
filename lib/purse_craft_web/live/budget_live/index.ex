defmodule PurseCraftWeb.BudgetLive.Index do
  @moduledoc false

  use PurseCraftWeb, :live_view

  alias PurseCraft.Budgeting
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Budgeting.Schemas.Envelope

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
  def render(assigns) do
    ~H"""
    <Layouts.budgeting flash={@flash} current_path={@current_path} current_scope={@current_scope}>
      <div class="space-y-6 w-full max-w-7xl mx-auto">
        <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 sm:gap-0">
          <div class="flex flex-col sm:flex-row sm:items-center gap-2 sm:gap-4">
            <h1 class="text-2xl font-bold">Budget - {@book.name}</h1>
            <div class="flex items-center">
              <button class="btn btn-ghost btn-sm">
                <.icon name="hero-chevron-left" class="h-4 w-4" />
              </button>
              <span class="font-medium mx-2">May 2025</span>
              <button class="btn btn-ghost btn-sm">
                <.icon name="hero-chevron-right" class="h-4 w-4" />
              </button>
            </div>
          </div>
          <div class="flex gap-2">
            <button class="btn btn-primary btn-sm sm:btn-md" phx-click="open_category_modal">
              Add Category
            </button>
            <button class="btn btn-outline btn-sm sm:btn-md">Auto-Assign</button>
          </div>
        </div>

        <%= if @category_modal_open do %>
          <div class="modal modal-open" role="dialog">
            <div class="modal-box">
              <h3 class="font-bold text-lg mb-4">{@modal_title}</h3>
              <.form for={@category_form} id="category-form" phx-submit={@modal_action}>
                <.input field={@category_form[:name]} type="text" label="Category Name" />
                <div class="modal-action">
                  <button type="button" class="btn" phx-click="reset-category-form">Cancel</button>
                  <button type="submit" class="btn btn-primary" phx-disable-with="Saving...">
                    {@modal_button}
                  </button>
                </div>
              </.form>
            </div>
            <div class="modal-backdrop" phx-click="close_category_modal"></div>
          </div>
        <% end %>

        <%= if @delete_modal_open do %>
          <div class="modal modal-open" role="dialog">
            <div class="modal-box">
              <h3 class="font-bold text-lg mb-4">Delete Category</h3>
              <p class="mb-4">
                Are you sure you want to delete the category "{@category_to_delete.name}"?
              </p>
              <p class="text-error mb-4">This action cannot be undone.</p>
              <div class="modal-action">
                <button type="button" class="btn" phx-click="close_delete_modal">Cancel</button>
                <button
                  type="button"
                  class="btn btn-error"
                  phx-click="delete_category"
                  phx-value-id={@category_to_delete.external_id}
                >
                  Delete
                </button>
              </div>
            </div>
            <div class="modal-backdrop" phx-click="close_delete_modal"></div>
          </div>
        <% end %>

        <%= if @envelope_modal_open do %>
          <div class="modal modal-open" role="dialog">
            <div class="modal-box">
              <h3 class="font-bold text-lg mb-4">{@envelope_modal_title}</h3>
              <.form for={@envelope_form} id="envelope-form" phx-submit={@envelope_modal_action}>
                <.input field={@envelope_form[:name]} type="text" label="Envelope Name" />
                <div class="modal-action">
                  <button type="button" class="btn" phx-click="reset-envelope-form">Cancel</button>
                  <button type="submit" class="btn btn-primary" phx-disable-with="Saving...">
                    {@envelope_modal_button}
                  </button>
                </div>
              </.form>
            </div>
            <div class="modal-backdrop" phx-click="close_envelope_modal"></div>
          </div>
        <% end %>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mt-6">
          <div class="card bg-success/10 border border-success/20">
            <div class="card-body p-4">
              <div class="flex flex-row md:flex-col items-center md:items-start justify-between md:justify-start">
                <h2 class="card-title text-sm text-success">Ready to Assign</h2>
                <p class="text-xl md:text-2xl font-bold md:mt-1">$1,250.00</p>
              </div>
            </div>
          </div>
          <div class="card bg-base-200">
            <div class="card-body p-4">
              <div class="flex flex-row md:flex-col items-center md:items-start justify-between md:justify-start">
                <h2 class="card-title text-sm">Assigned this Month</h2>
                <p class="text-xl md:text-2xl font-bold md:mt-1">$3,750.00</p>
              </div>
            </div>
          </div>
          <div class="card bg-base-200">
            <div class="card-body p-4">
              <div class="flex flex-row md:flex-col items-center md:items-start justify-between md:justify-start">
                <h2 class="card-title text-sm">Activity this Month</h2>
                <p class="text-xl md:text-2xl font-bold md:mt-1">-$2,130.45</p>
              </div>
            </div>
          </div>
        </div>

        <div class="space-y-2">
          <div class="overflow-x-auto">
            <div class="min-w-[600px]">
              <div id="budget-categories" phx-update="stream" class="space-y-4">
                <div :for={{dom_id, category} <- @streams.categories} id={dom_id} class="mb-4">
                  <div class="flex items-center justify-between py-2 border-b border-base-300 mb-1 group">
                    <div class="flex items-center gap-2 w-1/2">
                      <button class="btn btn-ghost btn-xs">
                        <.icon name="hero-chevron-down" class="h-4 w-4" />
                      </button>
                      <h3 class="font-bold">{category.name}</h3>
                      <button
                        class="btn btn-ghost btn-xs opacity-0 group-hover:opacity-100 transition-opacity"
                        phx-click="edit_category"
                        phx-value-id={category.external_id}
                      >
                        <.icon name="hero-pencil-square" class="h-4 w-4" />
                      </button>
                      <%= if Enum.empty?(category.envelopes) do %>
                        <button
                          class="btn btn-ghost btn-xs opacity-0 group-hover:opacity-100 transition-opacity text-error"
                          phx-click="open_delete_modal"
                          phx-value-id={category.external_id}
                        >
                          <.icon name="hero-trash" class="h-4 w-4" />
                        </button>
                      <% end %>
                      <button
                        class="btn btn-ghost btn-xs opacity-0 group-hover:opacity-100 transition-opacity text-success"
                        phx-click="open_envelope_modal"
                        phx-value-id={category.external_id}
                      >
                        <.icon name="hero-plus" class="h-4 w-4" />
                      </button>
                    </div>
                    <div class="flex justify-end w-1/2 text-xs sm:text-sm font-medium">
                      <span class="w-[80px] sm:w-[100px] text-right">Assigned</span>
                      <span class="w-[80px] sm:w-[100px] text-right">Activity</span>
                      <span class="w-[80px] sm:w-[100px] text-right">Available</span>
                    </div>
                  </div>

                  <div class="space-y-1">
                    <%= if is_struct(category.envelopes, Ecto.Association.NotLoaded) or Enum.empty?(category.envelopes) do %>
                      <div class="py-3 pl-6 sm:pl-8 text-sm text-base-content/60 italic">
                        No envelopes in this category yet
                      </div>
                    <% else %>
                      <.envelope_row
                        :for={envelope <- category.envelopes}
                        id={envelope.external_id}
                        name={envelope.name}
                        assigned="100.00"
                        activity="0.00"
                        available="100.00"
                      />
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.budgeting>
    """
  end

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :assigned, :string, required: true
  attr :activity, :string, required: true
  attr :available, :string, required: true

  defp envelope_row(assigns) do
    available_float =
      assigns
      |> Map.get(:available)
      |> String.replace(",", "")
      |> String.to_float()

    # coveralls-ignore-start
    available_class =
      cond do
        available_float < 0 -> "text-error"
        available_float > 0 -> "text-success"
        true -> ""
      end

    # coveralls-ignore-stop

    assigns = assign(assigns, :available_class, available_class)

    ~H"""
    <div class="flex items-center justify-between py-1 hover:bg-base-200 rounded-lg cursor-pointer group">
      <div class="flex items-center w-1/2">
        <span class="font-medium truncate pl-6 sm:pl-8">{@name}</span>
        <button
          class="btn btn-ghost btn-xs opacity-0 group-hover:opacity-100 transition-opacity ml-2"
          phx-click="edit_envelope"
          phx-value-id={@id}
        >
          <.icon name="hero-pencil-square" class="h-4 w-4" />
        </button>
      </div>
      <div class="flex justify-end w-1/2 text-xs sm:text-sm">
        <span class="w-[80px] sm:w-[100px] text-right">${@assigned}</span>
        <span class="w-[80px] sm:w-[100px] text-right">${@activity}</span>
        <span class={"w-[80px] sm:w-[100px] text-right font-medium #{@available_class}"}>
          ${@available}
        </span>
      </div>
    </div>
    """
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
