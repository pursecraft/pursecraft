defmodule PurseCraftWeb.WorkspaceLive.Form do
  @moduledoc false
  use PurseCraftWeb, :live_view

  alias PurseCraft.Core
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraftWeb.CoreComponents

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <CoreComponents.header>
        {@page_title}
        <:subtitle>Use this form to manage workspace records in your database.</:subtitle>
      </CoreComponents.header>

      <.form for={@form} id="workspace-form" phx-change="validate" phx-submit="save">
        <CoreComponents.input field={@form[:name]} type="text" label="Name" />
        <footer>
          <CoreComponents.button phx-disable-with="Saving..." variant="primary">
            Save Workspace
          </CoreComponents.button>
          <CoreComponents.button navigate={return_path(@current_scope, @return_to, @workspace)}>
            Cancel
          </CoreComponents.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to(_action), do: "index"

  defp apply_action(socket, :edit, %{"external_id" => external_id}) do
    case Core.fetch_workspace_by_external_id(socket.assigns.current_scope, external_id) do
      {:ok, workspace} ->
        socket
        |> assign(:page_title, "Edit Workspace")
        |> assign(:workspace, workspace)
        |> assign(:form, to_form(Core.change_workspace(workspace)))

      {:error, :not_found} ->
        socket
        |> put_flash(:error, "Workspace not found")
        |> push_navigate(to: ~p"/workspaces")

      {:error, :unauthorized} ->
        socket
        |> put_flash(:error, "You don't have access to this workspace")
        |> push_navigate(to: ~p"/workspaces")
    end
  end

  defp apply_action(socket, :new, _params) do
    workspace = %Workspace{}

    socket
    |> assign(:page_title, "New Workspace")
    |> assign(:workspace, workspace)
    |> assign(:form, to_form(Core.change_workspace(workspace)))
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"workspace" => workspace_params}, socket) do
    changeset = Core.change_workspace(socket.assigns.workspace, workspace_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"workspace" => workspace_params}, socket) do
    save_workspace(socket, socket.assigns.live_action, workspace_params)
  end

  defp save_workspace(socket, :edit, workspace_params) do
    %{current_scope: current_scope} = socket.assigns

    case Core.update_workspace(current_scope, socket.assigns.workspace, workspace_params) do
      {:ok, workspace} ->
        {:noreply,
         socket
         |> put_flash(:info, "Workspace updated successfully")
         |> push_navigate(to: return_path(current_scope, socket.assigns.return_to, workspace.external_id))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_workspace(socket, :new, workspace_params) do
    case Core.create_workspace(socket.assigns.current_scope, workspace_params) do
      {:ok, workspace} ->
        {:noreply,
         socket
         |> put_flash(:info, "Workspace created successfully")
         |> push_navigate(to: return_path(socket.assigns.current_scope, socket.assigns.return_to, workspace))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _workspace), do: ~p"/workspaces"
end
