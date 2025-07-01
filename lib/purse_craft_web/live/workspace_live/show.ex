defmodule PurseCraftWeb.WorkspaceLive.Show do
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
        Workspace {@workspace.id}
        <:subtitle>This is a workspace record from your database.</:subtitle>
        <:actions>
          <CoreComponents.button navigate={~p"/workspaces"}>
            <CoreComponents.icon name="hero-arrow-left" />
          </CoreComponents.button>
          <CoreComponents.button
            variant="primary"
            navigate={~p"/workspaces/#{@workspace.external_id}/edit?return_to=show"}
          >
            <CoreComponents.icon name="hero-pencil-square" /> Edit workspace
          </CoreComponents.button>
        </:actions>
      </CoreComponents.header>

      <CoreComponents.list>
        <:item title="Name">{@workspace.name}</:item>
      </CoreComponents.list>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"external_id" => external_id}, _session, socket) do
    case Core.fetch_workspace_by_external_id(socket.assigns.current_scope, external_id) do
      {:ok, workspace} ->
        PubSub.subscribe_workspace(workspace)

        {:ok,
         socket
         |> assign(:page_title, "Show Workspace")
         |> assign(:workspace, workspace)}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Workspace not found")
         |> push_navigate(to: ~p"/workspaces")}

      {:error, :unauthorized} ->
        {:ok,
         socket
         |> put_flash(:error, "You don't have access to this workspace")
         |> push_navigate(to: ~p"/workspaces")}
    end
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:updated, %Workspace{external_id: external_id} = workspace},
        %{assigns: %{workspace: %{external_id: external_id}}} = socket
      ) do
    {:noreply, assign(socket, :workspace, workspace)}
  end

  def handle_info(
        {:deleted, %Workspace{external_id: external_id}},
        %{assigns: %{workspace: %{external_id: external_id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current workspace was deleted.")
     |> push_navigate(to: ~p"/workspaces")}
  end
end
