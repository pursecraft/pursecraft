defmodule PurseCraftWeb.BudgetLive.Components.CategorySection do
  @moduledoc """
  Component for displaying a category section with its envelopes.
  """

  use Phoenix.Component

  alias PurseCraftWeb.Components.UI.Budgeting.Icon

  attr :id, :string, required: true
  attr :category, :map, required: true
  attr :expanded, :boolean, default: false
  slot :inner_block

  def category_section(assigns) do
    ~H"""
    <div id={@id} class="mb-4">
      <div class="flex items-center justify-between py-2 border-b border-base-300 mb-1 group">
        <div class="flex items-center gap-2 w-1/2">
          <button class="btn btn-ghost btn-xs">
            <Icon.icon name="chevron-down" class="h-4 w-4" />
          </button>
          <h3 class="font-bold">{@category.name}</h3>
          <button
            class="btn btn-ghost btn-xs opacity-0 group-hover:opacity-100 transition-opacity"
            phx-click="edit_category"
            phx-value-id={@category.external_id}
          >
            <Icon.icon name="pencil-square" class="h-4 w-4" />
          </button>
          <%= if Enum.empty?(@category.envelopes) do %>
            <button
              class="btn btn-ghost btn-xs opacity-0 group-hover:opacity-100 transition-opacity text-error"
              phx-click="open_delete_modal"
              phx-value-id={@category.external_id}
            >
              <Icon.icon name="trash" class="h-4 w-4" />
            </button>
          <% end %>
          <button
            class="btn btn-ghost btn-xs opacity-0 group-hover:opacity-100 transition-opacity text-success"
            phx-click="open_envelope_modal"
            phx-value-id={@category.external_id}
          >
            <Icon.icon name="plus" class="h-4 w-4" />
          </button>
        </div>
        <div class="flex justify-end w-1/2 text-xs sm:text-sm font-medium">
          <span class="w-[80px] sm:w-[100px] text-right">Assigned</span>
          <span class="w-[80px] sm:w-[100px] text-right">Activity</span>
          <span class="w-[80px] sm:w-[100px] text-right">Available</span>
        </div>
      </div>

      <div class="space-y-1">
        <%= if is_struct(@category.envelopes, Ecto.Association.NotLoaded) or Enum.empty?(@category.envelopes) do %>
          <div class="py-3 pl-6 sm:pl-8 text-sm text-base-content/60 italic">
            No envelopes in this category yet
          </div>
        <% else %>
          {render_slot(@inner_block)}
        <% end %>
      </div>
    </div>
    """
  end
end
