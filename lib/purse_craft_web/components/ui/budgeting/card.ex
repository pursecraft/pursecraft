defmodule PurseCraftWeb.Components.UI.Budgeting.Card do
  @moduledoc """
  Card components for the budgeting layout.
  Uses DaisyUI 5 card classes.
  """

  use Phoenix.Component

  attr :title, :string, required: true
  attr :class, :string, default: ""
  slot :actions
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div class={["card bg-base-100 shadow-md", @class]}>
      <div class="card-body">
        <div class="flex justify-between items-center mb-4">
          <h3 class="card-title">{@title}</h3>
          <div :if={@actions} class="flex gap-2">
            {render_slot(@actions)}
          </div>
        </div>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :amount, :string, required: true
  attr :variant, :string, values: ~w(default success info warning error), default: "default"
  attr :class, :string, default: ""

  def summary_card(assigns) do
    variant_class =
      case assigns.variant do
        "success" -> "bg-success/10 border border-success/20"
        "info" -> "bg-info/10 border border-info/20"
        "warning" -> "bg-warning/10 border border-warning/20"
        "error" -> "bg-error/10 border border-error/20"
        _ -> "bg-base-200"
      end

    title_class =
      case assigns.variant do
        "success" -> "text-success"
        "info" -> "text-info"
        "warning" -> "text-warning"
        "error" -> "text-error"
        _ -> ""
      end

    assigns =
      assigns
      |> assign(:card_class, variant_class)
      |> assign(:title_class, title_class)

    ~H"""
    <div class={["card", @card_class, @class]}>
      <div class="card-body p-4">
        <div class="flex flex-row md:flex-col items-center md:items-start justify-between md:justify-start">
          <h2 class={["card-title text-sm", @title_class]}>{@title}</h2>
          <p class="text-xl md:text-2xl font-bold md:mt-1">{@amount}</p>
        </div>
      </div>
    </div>
    """
  end
end
