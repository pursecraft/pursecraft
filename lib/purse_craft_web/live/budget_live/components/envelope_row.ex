defmodule PurseCraftWeb.BudgetLive.Components.EnvelopeRow do
  @moduledoc """
  Component for displaying an envelope row in the budget view.
  """

  use PurseCraftWeb, :html

  alias PurseCraftWeb.Components.UI.Budgeting.Icon

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :assigned, :string, required: true
  attr :activity, :string, required: true
  attr :available, :string, required: true

  def envelope_row(assigns) do
    available_float =
      assigns.available
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
    <div
      data-envelope-id={@id}
      class="flex items-center justify-between py-1 hover:bg-base-200 rounded-lg cursor-pointer group relative"
    >
      <button class="drag-handle absolute left-1 top-1/2 -translate-y-1/2 cursor-move btn btn-ghost btn-xs hidden sm:group-hover:inline-flex">
        <Icon.icon name="hero-bars-3" class="w-4 h-4" />
      </button>

      <div class="flex items-center w-1/2">
        <span class="font-medium truncate pl-8 sm:pl-10">{@name}</span>
        <button
          class="btn btn-ghost btn-xs opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity ml-2"
          phx-click="edit_envelope"
          phx-value-id={@id}
        >
          <Icon.icon name="hero-pencil-square" class="h-4 w-4" />
        </button>
        <button
          class="btn btn-ghost btn-xs opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity text-error"
          phx-click="delete_envelope_confirm"
          phx-value-id={@id}
        >
          <Icon.icon name="hero-trash" class="h-4 w-4" />
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
end
