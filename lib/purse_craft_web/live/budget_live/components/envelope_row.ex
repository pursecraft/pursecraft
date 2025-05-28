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
    <div class="flex items-center justify-between py-1 hover:bg-base-200 rounded-lg cursor-pointer group">
      <div class="flex items-center w-1/2">
        <span class="font-medium truncate pl-6 sm:pl-8">{@name}</span>
        <button
          class="btn btn-ghost btn-xs opacity-0 group-hover:opacity-100 transition-opacity ml-2"
          phx-click="edit_envelope"
          phx-value-id={@id}
        >
          <Icon.icon name="pencil-square" class="h-4 w-4" />
        </button>
        <button
          class="btn btn-ghost btn-xs opacity-0 group-hover:opacity-100 transition-opacity text-error"
          phx-click="delete_envelope_confirm"
          phx-value-id={@id}
        >
          <Icon.icon name="trash" class="h-4 w-4" />
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
