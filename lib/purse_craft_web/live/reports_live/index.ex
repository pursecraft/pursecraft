defmodule PurseCraftWeb.ReportsLive.Index do
  @moduledoc """
  LiveView for the Report page, which shows spending trends and reports.
  """
  use PurseCraftWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Reports")
      |> assign(:current_path, "/reports")

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.budgeting flash={@flash} current_path={@current_path} current_scope={@current_scope}>
      <div class="space-y-6">
        <div class="flex justify-between items-center">
          <h1 class="text-2xl font-bold">Reports</h1>
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
