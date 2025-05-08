defmodule PurseCraftWeb.BudgetLive.Index do
  @moduledoc """
  LiveView for the budgeting page, inspired by YNAB's budgeting interface.
  """
  use PurseCraftWeb, :live_view

  alias PurseCraft.Budgeting

  @impl Phoenix.LiveView
  def mount(%{"external_id" => external_id}, _session, socket) do
    book = Budgeting.get_book_by_external_id!(socket.assigns.current_scope, external_id)

    socket =
      socket
      |> assign(:page_title, "Budget - #{book.name}")
      |> assign(:current_path, "/books/#{book.external_id}/budget")
      |> assign(:book, book)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.budgeting flash={@flash} current_path={@current_path} current_scope={@current_scope}>
      <div class="space-y-6">
        <!-- Budget Header -->
        <div class="flex justify-between items-center">
          <div class="flex items-center gap-4">
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
            <button class="btn btn-primary">Add Category</button>
            <button class="btn btn-outline">Auto-Assign</button>
          </div>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div class="card bg-success/10 border border-success/20">
            <div class="card-body p-4">
              <h2 class="card-title text-sm text-success">Ready to Assign</h2>
              <p class="text-2xl font-bold">$1,250.00</p>
            </div>
          </div>
          <div class="card bg-base-200">
            <div class="card-body p-4">
              <h2 class="card-title text-sm">Assigned this Month</h2>
              <p class="text-2xl font-bold">$3,750.00</p>
            </div>
          </div>
          <div class="card bg-base-200">
            <div class="card-body p-4">
              <h2 class="card-title text-sm">Activity this Month</h2>
              <p class="text-2xl font-bold">-$2,130.45</p>
            </div>
          </div>
        </div>
        
        <div class="space-y-4">
          <div class="space-y-2">
            <div class="flex items-center justify-between py-2 border-b border-base-300">
              <div class="flex items-center gap-2">
                <button class="btn btn-ghost btn-xs">
                  <.icon name="hero-chevron-down" class="h-4 w-4" />
                </button>
                <h3 class="font-bold">Immediate Obligations</h3>
              </div>
              <div class="flex gap-8 text-sm font-medium">
                <span class="w-24 text-right">Assigned</span>
                <span class="w-24 text-right">Activity</span>
                <span class="w-24 text-right">Available</span>
              </div>
            </div>
            
            <.category_row
              name="Rent/Mortgage"
              assigned="1,500.00"
              activity="0.00"
              available="1,500.00"
            />
            <.category_row name="Electric" assigned="120.00" activity="-95.40" available="24.60" />
            <.category_row name="Water" assigned="45.00" activity="0.00" available="45.00" />
            <.category_row name="Internet" assigned="75.00" activity="-75.00" available="0.00" />
            <.category_row name="Groceries" assigned="600.00" activity="-423.65" available="176.35" />
            <.category_row name="Overspent" assigned="50.00" activity="-75.00" available="-25.00" />
          </div>
          
          <div class="space-y-2">
            <div class="flex items-center justify-between py-2 border-b border-base-300">
              <div class="flex items-center gap-2">
                <button class="btn btn-ghost btn-xs">
                  <.icon name="hero-chevron-down" class="h-4 w-4" />
                </button>
                <h3 class="font-bold">True Expenses</h3>
              </div>
              <div class="flex gap-8 text-sm font-medium">
                <span class="w-24 text-right">Assigned</span>
                <span class="w-24 text-right">Activity</span>
                <span class="w-24 text-right">Available</span>
              </div>
            </div>
            
            <.category_row
              name="Auto Maintenance"
              assigned="100.00"
              activity="0.00"
              available="100.00"
            />
            <.category_row
              name="Home Maintenance"
              assigned="150.00"
              activity="-42.50"
              available="107.50"
            />
            <.category_row name="Clothing" assigned="50.00" activity="-23.75" available="26.25" />
            <.category_row name="Medical/Health" assigned="200.00" activity="0.00" available="200.00" />
          </div>
          
          <div class="space-y-2">
            <div class="flex items-center justify-between py-2 border-b border-base-300">
              <div class="flex items-center gap-2">
                <button class="btn btn-ghost btn-xs">
                  <.icon name="hero-chevron-down" class="h-4 w-4" />
                </button>
                <h3 class="font-bold">Quality of Life</h3>
              </div>
              <div class="flex gap-8 text-sm font-medium">
                <span class="w-24 text-right">Assigned</span>
                <span class="w-24 text-right">Activity</span>
                <span class="w-24 text-right">Available</span>
              </div>
            </div>
            
            <.category_row name="Dining Out" assigned="300.00" activity="-245.30" available="54.70" />
            <.category_row name="Entertainment" assigned="150.00" activity="-86.35" available="63.65" />
            <.category_row name="Vacation" assigned="200.00" activity="0.00" available="200.00" />
            <.category_row name="Gifts" assigned="100.00" activity="-50.00" available="50.00" />
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

    available_class =
      cond do
        available_float < 0 -> "text-error"
        available_float > 0 -> "text-success"
        true -> ""
      end

    assigns = assign(assigns, :available_class, available_class)

    ~H"""
    <div class="flex items-center justify-between py-2 pl-8 pr-2 hover:bg-base-200 rounded-lg cursor-pointer">
      <span class="font-medium">{@name}</span>
      <div class="flex gap-8 text-sm">
        <span class="w-24 text-right">${@assigned}</span>
        <span class="w-24 text-right">${@activity}</span>
        <span class={"w-24 text-right font-medium #{@available_class}"}>${@available}</span>
      </div>
    </div>
    """
  end
end
