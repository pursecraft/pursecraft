defmodule PurseCraftWeb.WorkspaceLive.Components.BudgetHeader do
  @moduledoc """
  Component for displaying the budget header with month navigation.
  """

  use PurseCraftWeb, :html

  alias PurseCraftWeb.Components.UI.Core.Icon

  attr :workspace_name, :string, required: true
  attr :current_month, :string, default: "May 2025"
  attr :on_add_category, :string, default: "open_category_modal"
  attr :on_auto_assign, :string, default: nil
  attr :target, :any, default: nil

  def render(assigns) do
    ~H"""
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 sm:gap-0">
      <div class="flex flex-col sm:flex-row sm:items-center gap-2 sm:gap-4">
        <h1 class="text-2xl font-bold">Budget - {@workspace_name}</h1>
        <div class="flex items-center">
          <button class="btn btn-ghost btn-sm">
            <Icon.render name="hero-chevron-left" class="h-4 w-4" />
          </button>
          <span class="font-medium mx-2">{@current_month}</span>
          <button class="btn btn-ghost btn-sm">
            <Icon.render name="hero-chevron-right" class="h-4 w-4" />
          </button>
        </div>
      </div>
      <div class="flex gap-2">
        <button
          class="btn btn-primary btn-sm sm:btn-md"
          phx-click={@on_add_category}
          phx-target={@target}
        >
          Add Category
        </button>
        <button
          :if={@on_auto_assign}
          class="btn btn-outline btn-sm sm:btn-md"
          phx-click={@on_auto_assign}
          phx-target={@target}
        >
          Auto-Assign
        </button>
      </div>
    </div>
    """
  end
end
