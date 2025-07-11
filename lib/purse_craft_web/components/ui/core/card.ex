defmodule PurseCraftWeb.Components.UI.Core.Card do
  @moduledoc false
  use PurseCraftWeb, :html

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
    variant_class = get_variant_class(assigns.variant)
    title_class = get_title_class(assigns.variant)

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

  defp get_variant_class("success"), do: "bg-success/10 border border-success/20"
  defp get_variant_class("info"), do: "bg-info/10 border border-info/20"
  defp get_variant_class("warning"), do: "bg-warning/10 border border-warning/20"
  defp get_variant_class("error"), do: "bg-error/10 border border-error/20"
  defp get_variant_class(_variant), do: "bg-base-200"

  defp get_title_class("success"), do: "text-success"
  defp get_title_class("info"), do: "text-info"
  defp get_title_class("warning"), do: "text-warning"
  defp get_title_class("error"), do: "text-error"
  defp get_title_class(_variant), do: ""
end
