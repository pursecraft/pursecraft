defmodule PurseCraftWeb.Components.UI.Core.FlashGroup do
  @moduledoc """
  Flash group component that renders multiple flash messages and connection status.
  """
  use PurseCraftWeb, :html

  alias PurseCraftWeb.Components.UI.Core.Flash
  alias PurseCraftWeb.Components.UI.Core.Icon
  alias PurseCraftWeb.Components.UI.Core.JSCommands

  @doc """
  Renders a flash group containing info and error flash messages, 
  plus connection status messages.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def render(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <Flash.render kind={:info} flash={@flash} />
      <Flash.render kind={:error} flash={@flash} />

      <Flash.render
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={
          JSCommands.show(".phx-client-error #client-error")
          |> Phoenix.LiveView.JS.remove_attribute("hidden")
        }
        phx-connected={
          JSCommands.hide("#client-error") |> Phoenix.LiveView.JS.set_attribute({"hidden", ""})
        }
        hidden
      >
        {gettext("Attempting to reconnect")}
        <Icon.render name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </Flash.render>

      <Flash.render
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={
          JSCommands.show(".phx-client-error #client-error")
          |> Phoenix.LiveView.JS.remove_attribute("hidden")
        }
        phx-connected={
          JSCommands.hide("#client-error") |> Phoenix.LiveView.JS.set_attribute({"hidden", ""})
        }
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <Icon.render name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </Flash.render>
    </div>
    """
  end
end
