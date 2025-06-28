defmodule PurseCraftWeb.ReportsLive.Index do
  @moduledoc false

  use PurseCraftWeb, :live_view

  alias PurseCraft.Accounting
  alias PurseCraft.Budgeting

  @impl Phoenix.LiveView
  def mount(%{"external_id" => external_id}, _session, socket) do
    case Budgeting.fetch_book_by_external_id(socket.assigns.current_scope, external_id) do
      {:ok, book} ->
        accounts = Accounting.list_accounts(socket.assigns.current_scope, book)

        socket =
          socket
          |> assign(:page_title, "Reports - #{book.name}")
          |> assign(:current_path, "/books/#{book.external_id}/reports")
          |> assign(:book, book)
          |> assign(:accounts, accounts)

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
    <Layouts.budgeting
      flash={@flash}
      current_path={@current_path}
      current_scope={@current_scope}
      accounts={@accounts}
    >
      <div class="space-y-6">
        <div class="flex justify-between items-center">
          <h1 class="text-2xl font-bold">Reports - {@book.name}</h1>
          <div class="flex gap-2">
            <button class="btn btn-outline">Export</button>
          </div>
        </div>

        <div class="bg-base-200 rounded-xl p-6">
          <h2 class="text-xl font-bold mb-4">Spending Trends</h2>
          <div class="h-64 flex items-center justify-center border border-dashed border-base-300 rounded-lg">
            <div class="text-center">
              <p class="text-base-content/70">Chart visualization will be implemented here</p>
              <p class="text-sm text-base-content/50">Spending trends over time</p>
            </div>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div class="bg-base-200 rounded-xl p-6">
            <h2 class="text-xl font-bold mb-4">Top Categories</h2>
            <div class="h-64 flex items-center justify-center border border-dashed border-base-300 rounded-lg">
              <div class="text-center">
                <p class="text-base-content/70">Pie chart will be implemented here</p>
                <p class="text-sm text-base-content/50">Showing top spending categories</p>
              </div>
            </div>
          </div>

          <div class="bg-base-200 rounded-xl p-6">
            <h2 class="text-xl font-bold mb-4">Income vs Spending</h2>
            <div class="h-64 flex items-center justify-center border border-dashed border-base-300 rounded-lg">
              <div class="text-center">
                <p class="text-base-content/70">Bar chart will be implemented here</p>
                <p class="text-sm text-base-content/50">Income vs spending by month</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.budgeting>
    """
  end
end
