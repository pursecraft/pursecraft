defmodule PurseCraftWeb.Components.UI.Budgeting.Modal do
  @moduledoc """
  Modal component for the budgeting layout.
  Uses DaisyUI 5 modal classes.
  """

  use Phoenix.Component

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_close, :string, default: nil
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div :if={@show} class="modal modal-open" role="dialog">
      <div class="modal-box">
        {render_slot(@inner_block)}
      </div>
      <div class="modal-backdrop" phx-click={@on_close}></div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :title, :string, required: true
  attr :on_close, :string, default: nil
  attr :on_confirm, :string, default: nil
  attr :confirm_value, :string, default: nil
  attr :confirm_text, :string, default: "Delete"
  attr :confirm_class, :string, default: "btn-error"
  slot :inner_block, required: true

  def confirmation_modal(assigns) do
    ~H"""
    <div :if={@show} class="modal modal-open" role="dialog">
      <div class="modal-box">
        <h3 class="font-bold text-lg mb-4">{@title}</h3>
        {render_slot(@inner_block)}
        <div class="modal-action">
          <button type="button" class="btn" phx-click={@on_close}>Cancel</button>
          <button
            :if={@on_confirm}
            type="button"
            class={"btn #{@confirm_class}"}
            phx-click={@on_confirm}
            phx-value-id={@confirm_value}
          >
            {@confirm_text}
          </button>
        </div>
      </div>
      <div class="modal-backdrop" phx-click={@on_close}></div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :title, :string, required: true
  attr :on_close, :string, default: nil
  slot :inner_block, required: true
  slot :actions, required: true

  def form_modal(assigns) do
    ~H"""
    <div :if={@show} class="modal modal-open" role="dialog">
      <div class="modal-box">
        <h3 class="font-bold text-lg mb-4">{@title}</h3>
        {render_slot(@inner_block)}
        <div class="modal-action">
          {render_slot(@actions)}
        </div>
      </div>
      <div class="modal-backdrop" phx-click={@on_close}></div>
    </div>
    """
  end
end
