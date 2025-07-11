defmodule PurseCraftWeb.Components.UI.Core.Icon do
  @moduledoc false
  use PurseCraftWeb, :html

  attr :name, :string, required: true
  attr :class, :string, default: ""
  attr :id, :string, default: nil

  def render(%{name: "hero-" <> _icon_name} = assigns) do
    ~H"""
    <span id={@id} class={[@name, @class]} />
    """
  end
end
