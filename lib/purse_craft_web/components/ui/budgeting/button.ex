defmodule PurseCraftWeb.Components.UI.Budgeting.Button do
  @moduledoc """
  Button components for the budgeting layout.
  Uses DaisyUI 5 button classes.
  """

  use Phoenix.Component

  attr :type, :string, default: "button"
  attr :class, :string, default: ""
  attr :rest, :global, include: ~w(phx-click phx-value-id phx-disable-with disabled)
  slot :inner_block, required: true

  def primary(assigns) do
    ~H"""
    <button type={@type} class={"btn btn-primary #{@class}"} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :type, :string, default: "button"
  attr :class, :string, default: ""
  attr :rest, :global, include: ~w(phx-click phx-value-id phx-disable-with disabled)
  slot :inner_block, required: true

  def secondary(assigns) do
    ~H"""
    <button type={@type} class={"btn #{@class}"} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :type, :string, default: "button"
  attr :class, :string, default: ""
  attr :rest, :global, include: ~w(phx-click phx-value-id phx-disable-with disabled)
  slot :inner_block, required: true

  def danger(assigns) do
    ~H"""
    <button type={@type} class={"btn btn-error #{@class}"} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :type, :string, default: "button"
  attr :class, :string, default: ""
  attr :rest, :global, include: ~w(phx-click phx-value-id phx-disable-with disabled)
  slot :inner_block, required: true

  def outline(assigns) do
    ~H"""
    <button type={@type} class={"btn btn-outline #{@class}"} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :type, :string, default: "button"
  attr :class, :string, default: ""
  attr :rest, :global, include: ~w(phx-click phx-value-id phx-disable-with disabled)
  slot :inner_block, required: true

  def ghost(assigns) do
    ~H"""
    <button type={@type} class={"btn btn-ghost #{@class}"} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :type, :string, default: "button"
  attr :variant, :string, values: ~w(primary secondary danger outline ghost), default: "secondary"
  attr :size, :string, values: ~w(xs sm md lg), default: "md"
  attr :class, :string, default: ""
  attr :rest, :global, include: ~w(phx-click phx-value-id phx-disable-with disabled)
  slot :inner_block, required: true

  def button(assigns) do
    variant_class =
      case assigns.variant do
        "primary" -> "btn-primary"
        "danger" -> "btn-error"
        "outline" -> "btn-outline"
        "ghost" -> "btn-ghost"
        _ -> ""
      end

    size_class =
      case assigns.size do
        "xs" -> "btn-xs"
        "sm" -> "btn-sm"
        "lg" -> "btn-lg"
        _ -> ""
      end

    assigns = assign(assigns, :combined_class, "btn #{variant_class} #{size_class} #{assigns.class}")

    ~H"""
    <button type={@type} class={@combined_class} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end
end
