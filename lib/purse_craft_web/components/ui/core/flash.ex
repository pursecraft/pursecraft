defmodule PurseCraftWeb.Components.UI.Core.Flash do
  @moduledoc """
  Individual flash message component for displaying notifications.
  """
  use PurseCraftWeb, :html

  alias PurseCraftWeb.Components.UI.Core.Icon
  alias PurseCraftWeb.Components.UI.Core.JSCommands

  @doc """
  Renders flash messages.

  ## Examples

      <Flash.render kind={:info} flash={@flash} />
      <Flash.render kind={:info} phx-mounted={JSCommands.show("#flash")}>Welcome Back!</Flash.render>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def render(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={
        Phoenix.LiveView.JS.push("lv:clear-flash", value: %{key: @kind}) |> JSCommands.hide("##{@id}")
      }
      role="alert"
      class="toast toast-top toast-end z-50"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <Icon.render :if={@kind == :info} name="hero-information-circle-mini" class="size-5 shrink-0" />
        <Icon.render
          :if={@kind == :error}
          name="hero-exclamation-circle-mini"
          class="size-5 shrink-0"
        />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
          <Icon.render name="hero-x-mark-solid" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end
end
