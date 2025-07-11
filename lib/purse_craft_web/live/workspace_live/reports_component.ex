defmodule PurseCraftWeb.WorkspaceLive.ReportsComponent do
  @moduledoc false
  use PurseCraftWeb, :live_component

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h1 class="text-2xl font-bold mb-4">Reports - {@workspace.name}</h1>
      <p>Reports functionality will be implemented here</p>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
end
