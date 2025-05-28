defmodule PurseCraftWeb.Components.UI.Budgeting.Button do
  @moduledoc """
  Button components for the budgeting layout.
  Uses DaisyUI 5 button classes.
  """

  use PurseCraftWeb, :html

  attr :type, :string, default: "button"
  attr :class, :string, default: ""
  attr :rest, :global, include: ~w(phx-click phx-value-id phx-disable-with disabled form)
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
  attr :rest, :global, include: ~w(phx-click phx-value-id phx-disable-with disabled form)
  slot :inner_block, required: true

  def secondary(assigns) do
    ~H"""
    <button type={@type} class={"btn #{@class}"} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  # TODO: Remove the coveralls ignore once we start using these

  # coveralls-ignore-start

  attr :type, :string, default: "button"
  attr :class, :string, default: ""
  attr :rest, :global, include: ~w(phx-click phx-value-id phx-disable-with disabled form)
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
  attr :rest, :global, include: ~w(phx-click phx-value-id phx-disable-with disabled form)
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
  attr :rest, :global, include: ~w(phx-click phx-value-id phx-disable-with disabled form)
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
  attr :rest, :global, include: ~w(phx-click phx-value-id phx-disable-with disabled form)
  slot :inner_block, required: true

  def button(assigns) do
    variant_class = get_variant_class(assigns.variant)
    size_class = get_size_class(assigns.size)

    assigns = assign(assigns, :combined_class, "btn #{variant_class} #{size_class} #{assigns.class}")

    ~H"""
    <button type={@type} class={@combined_class} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp get_variant_class("primary"), do: "btn-primary"
  defp get_variant_class("danger"), do: "btn-error"
  defp get_variant_class("outline"), do: "btn-outline"
  defp get_variant_class("ghost"), do: "btn-ghost"
  defp get_variant_class(_variant), do: ""

  defp get_size_class("xs"), do: "btn-xs"
  defp get_size_class("sm"), do: "btn-sm"
  defp get_size_class("lg"), do: "btn-lg"
  defp get_size_class(_size), do: ""

  # coveralls-ignore-stop
end
