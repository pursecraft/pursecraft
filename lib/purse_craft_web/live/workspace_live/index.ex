defmodule PurseCraftWeb.WorkspaceLive.Index do
  @moduledoc false
  use PurseCraftWeb, :live_view

  alias PurseCraft.Core
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.PubSub
  alias PurseCraftWeb.CoreComponents

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <CoreComponents.header>
        Listing Workspaces
        <:actions>
          <CoreComponents.button variant="primary" navigate={~p"/workspaces/new"}>
            <CoreComponents.icon name="hero-plus" /> New Workspace
          </CoreComponents.button>
        </:actions>
      </CoreComponents.header>

      <CoreComponents.table
        id="workspaces"
        rows={@streams.workspaces}
        row_id={fn {_id, workspace} -> "workspaces-#{workspace.external_id}" end}
        row_click={fn {_id, workspace} -> JS.navigate(~p"/workspaces/#{workspace.external_id}") end}
      >
        <:col :let={{_id, workspace}} label="Name">{workspace.name}</:col>
        <:action :let={{_id, workspace}}>
          <div class="sr-only">
            <.link navigate={~p"/workspaces/#{workspace.external_id}"}>Show</.link>
          </div>
          <.link navigate={~p"/workspaces/#{workspace.external_id}/budget"}>
            Go to Budget View
          </.link>
          <.link navigate={~p"/workspaces/#{workspace.external_id}/edit"}>Edit</.link>
        </:action>
        <:action :let={{_id, workspace}}>
          <.link
            phx-click={
              JS.push("delete", value: %{external_id: workspace.external_id})
              |> CoreComponents.hide("#workspaces-#{workspace.external_id}")
            }
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </CoreComponents.table>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    PubSub.subscribe_user_workspaces(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, "Listing Workspaces")
     |> stream(:workspaces, Core.list_workspaces(socket.assigns.current_scope))}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"external_id" => external_id}, socket) do
    case Core.fetch_workspace_by_external_id(socket.assigns.current_scope, external_id) do
      {:ok, workspace} ->
        case Core.delete_workspace(socket.assigns.current_scope, workspace) do
          {:ok, _workspace} ->
            {:noreply, stream_delete_by_dom_id(socket, :workspaces, "workspaces-#{workspace.external_id}")}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Failed to delete workspace")}
        end

      # coveralls-ignore-start
      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Workspace not found")}

      # coveralls-ignore-stop

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You don't have access to this workspace")}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:deleted, %Workspace{} = workspace}, socket) do
    {:noreply, stream_delete_by_dom_id(socket, :workspaces, "workspaces-#{workspace.external_id}")}
  end

  @impl Phoenix.LiveView
  def handle_info({type, %Workspace{}}, socket) when type in [:created, :updated] do
    workspaces = Core.list_workspaces(socket.assigns.current_scope)
    {:noreply, stream(socket, :workspaces, workspaces, reset: true)}
  end
end
