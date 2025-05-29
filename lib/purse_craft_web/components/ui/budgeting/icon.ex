defmodule PurseCraftWeb.Components.UI.Budgeting.Icon do
  @moduledoc """
  Icon component for the budgeting layout.
  Uses Heroicons.
  """

  use PurseCraftWeb, :html

  attr :name, :string, required: true
  attr :class, :string, default: ""
  attr :id, :string, default: nil

  def icon(assigns) do
    ~H"""
    <span id={@id} class={["hero-#{@name}", @class]}></span>
    """
  end
end
