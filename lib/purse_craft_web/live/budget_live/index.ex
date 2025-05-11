defmodule PurseCraftWeb.BudgetLive.Index do
  @moduledoc false

  use PurseCraftWeb, :live_view

  alias PurseCraft.Budgeting
  alias PurseCraft.Budgeting.Schemas.Category

  @impl Phoenix.LiveView
  def mount(%{"external_id" => external_id}, _session, socket) do
    preloads = [categories: :envelopes]

    case Budgeting.fetch_book_by_external_id(socket.assigns.current_scope, external_id, preload: preloads) do
      {:ok, book} ->
        socket =
          socket
          |> assign(:page_title, "Budget - #{book.name}")
          |> assign(:current_path, "/books/#{book.external_id}/budget")
          |> assign(:book, book)
          |> assign(:category_form, to_form(Budgeting.change_category(%Category{})))
          |> assign(:category_modal_open, false)
          |> stream_configure(:categories, dom_id: &"categories-#{&1.external_id}")
          |> stream(:categories, book.categories)

        {:ok, socket}

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
              <h3 class="font-bold text-lg mb-4">Add New Category</h3>
              <.form for={@category_form} id="category-form" phx-submit="create-category">
                <.input field={@category_form[:name]} type="text" label="Category Name" />
                <div class="modal-action">
                  <button type="button" class="btn" phx-click="reset-category-form">Cancel</button>
                  <button type="submit" class="btn btn-primary" phx-disable-with="Creating...">
                    Create
                  </button>
                </div>
              </.form>
            </div>
            <div class="modal-backdrop" phx-click="close_category_modal"></div>
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
                  <div class="flex items-center justify-between py-2 border-b border-base-300 mb-1">
                    <div class="flex items-center gap-2 w-1/2">
                      <button class="btn btn-ghost btn-xs">
                        <.icon name="hero-chevron-down" class="h-4 w-4" />
                      </button>
                      <h3 class="font-bold">{category.name}</h3>
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
                      <div
                        :for={envelope <- category.envelopes}
                        id={"envelope-#{envelope.external_id}"}
                      >
                        <.category_row
                          name={envelope.name}
                          assigned="100.00"
                          activity="0.00"
                          available="100.00"
                        />
                      </div>
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

  attr :name, :string, required: true
  attr :assigned, :string, required: true
  attr :activity, :string, required: true
  attr :available, :string, required: true

  defp category_row(assigns) do
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
    <div class="flex items-center justify-between py-1 hover:bg-base-200 rounded-lg cursor-pointer">
      <span class="font-medium truncate w-1/2 pl-6 sm:pl-8">{@name}</span>
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
     |> assign(:category_modal_open, false)}
  end

  @impl Phoenix.LiveView
  def handle_event("create-category", %{"category" => category_params}, socket) do
    case Budgeting.create_category(socket.assigns.current_scope, socket.assigns.book, category_params) do
      {:ok, category} ->
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
end
