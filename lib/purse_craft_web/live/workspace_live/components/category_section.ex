defmodule PurseCraftWeb.WorkspaceLive.Components.CategorySection do
  @moduledoc """
  Component for displaying a category section with its envelopes.
  """

  use PurseCraftWeb, :html

  alias Phoenix.LiveView.JS
  alias PurseCraftWeb.Components.UI.Core.Icon

  attr :id, :string, required: true
  attr :category, :map, required: true
  attr :target, :any, default: nil
  slot :inner_block

  def render(assigns) do
    ~H"""
    <div
      id={@id}
      data-category-id={@category.external_id}
      data-role="category-actions"
      data-target={@category.external_id}
      class="mb-4"
    >
      <div class="flex items-center justify-between py-2 border-b border-base-300 mb-1 group">
        <div class="flex items-center gap-2 w-1/2">
          <button class="drag-handle cursor-move btn btn-ghost btn-xs hidden sm:group-hover:inline-flex">
            <Icon.render name="hero-bars-3" class="w-4 h-4" />
          </button>
          <button class="btn btn-ghost btn-xs" phx-click={toggle_category(@category.external_id)}>
            <Icon.render
              name="hero-chevron-down"
              class="h-4 w-4 transition-transform"
              id={"toggle-icon-#{@category.external_id}"}
            />
          </button>
          <h3 class="font-bold">{@category.name}</h3>
          <button
            class="btn btn-ghost btn-xs opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity"
            data-role="edit-category"
            phx-click="edit_category"
            phx-value-id={@category.external_id}
            phx-target={@target}
          >
            <Icon.render name="hero-pencil-square" class="h-4 w-4" />
          </button>
          <%= if Enum.empty?(@category.envelopes) do %>
            <button
              class="btn btn-ghost btn-xs opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity text-error"
              phx-click="delete_category_confirm"
              phx-value-id={@category.external_id}
              phx-target={@target}
            >
              <Icon.render name="hero-trash" class="h-4 w-4" />
            </button>
          <% end %>
          <button
            class="btn btn-ghost btn-xs opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity text-success"
            data-role="add-envelope"
            phx-click="new_envelope"
            phx-value-id={@category.external_id}
            phx-target={@target}
          >
            <Icon.render name="hero-plus" class="h-4 w-4" />
          </button>
        </div>
        <div class="flex justify-end w-1/2 text-xs sm:text-sm font-medium">
          <span class="w-[80px] sm:w-[100px] text-right">Assigned</span>
          <span class="w-[80px] sm:w-[100px] text-right">Activity</span>
          <span class="w-[80px] sm:w-[100px] text-right">Available</span>
        </div>
      </div>

      <div class="space-y-1" id={"category-content-#{@category.external_id}"}>
        <%= if is_struct(@category.envelopes, Ecto.Association.NotLoaded) or Enum.empty?(@category.envelopes) do %>
          <div class="py-3 pl-6 sm:pl-8 text-sm text-base-content/60 italic">
            No envelopes in this category yet
          </div>
        <% else %>
          <div
            id={"envelope-list-#{@category.external_id}"}
            data-category-id={@category.external_id}
            phx-hook="EnvelopeDragDrop"
            class="space-y-1"
          >
            {render_slot(@inner_block)}
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp toggle_category(category_id) do
    [to: "#category-content-#{category_id}"]
    |> JS.toggle()
    |> JS.toggle_class("-rotate-90", to: "#toggle-icon-#{category_id}")
  end
end
