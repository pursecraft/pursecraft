defmodule PurseCraftWeb.Components.UI.Budgeting.Icon do
  @moduledoc """
  Icon component for the budgeting layout.
  Uses Heroicons.
  """

  use Phoenix.Component

  attr :name, :string, required: true
  attr :class, :string, default: ""

  def icon(assigns) do
    ~H"""
    <span class={["hero-#{@name}", @class]} />
    """
  end
end
