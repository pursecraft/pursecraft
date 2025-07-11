defmodule PurseCraftWeb.WorkspaceLive.Show do
  @moduledoc false
  use PurseCraftWeb, :live_view

  alias PurseCraft.Accounting
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Core
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.PubSub
  alias PurseCraftWeb.Components.UI.Core.FlashGroup
  alias PurseCraftWeb.WorkspaceLive.AccountsComponent
  alias PurseCraftWeb.WorkspaceLive.BudgetComponent
  alias PurseCraftWeb.WorkspaceLive.Components.Sidebar
  alias PurseCraftWeb.WorkspaceLive.ReportsComponent

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100">
      <FlashGroup.render flash={@flash} />

      <div :if={@workspace} class="flex h-screen overflow-hidden">
        <.live_component
          module={Sidebar}
          id="workspace-sidebar"
          workspace={@workspace}
          accounts={@accounts}
          current_scope={@current_scope}
          current_path={@current_path}
        />

        <main class="flex-1 overflow-y-auto">
          <.live_component
            :if={@live_action == :budget}
            module={BudgetComponent}
            id="budget-component"
            workspace={@workspace}
            current_scope={@current_scope}
          />

          <.live_component
            :if={@live_action == :reports}
            module={ReportsComponent}
            id="reports-component"
            workspace={@workspace}
            current_scope={@current_scope}
          />

          <.live_component
            :if={@live_action == :accounts}
            module={AccountsComponent}
            id="accounts-component"
            workspace={@workspace}
            current_scope={@current_scope}
          />
        </main>
      </div>

      <div :if={!@workspace} class="flex items-center justify-center min-h-screen">
        <div class="loading loading-spinner loading-lg"></div>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"external_id" => external_id}, _session, socket) do
    case Core.fetch_workspace_by_external_id(socket.assigns.current_scope, external_id) do
      {:ok, workspace} ->
        if connected?(socket) do
          PubSub.subscribe_workspace(workspace)

          accounts = Accounting.list_accounts(socket.assigns.current_scope, workspace)
          subscribe_to_accounts(accounts)

          {:ok,
           socket
           |> assign(:workspace, workspace)
           |> assign(:accounts, accounts)
           |> assign(:current_path, "")}
        else
          {:ok,
           socket
           |> assign(:workspace, workspace)
           |> assign(:accounts, [])
           |> assign(:current_path, "")}
        end

      {:error, :unauthorized} ->
        {:ok,
         socket
         |> put_flash(:error, "You don't have access to this workspace")
         |> redirect(to: ~p"/workspaces")}
    end
  end

  @impl Phoenix.LiveView
  def handle_params(_params, uri, socket) do
    current_path = URI.parse(uri).path
    workspace = socket.assigns.workspace

    if socket.assigns.live_action == :show && workspace do
      {:noreply, push_navigate(socket, to: ~p"/workspaces/#{workspace.external_id}/budget")}
    else
      {:noreply,
       socket
       |> assign(:page_title, page_title_for_action(socket.assigns.live_action, workspace))
       |> assign(:current_path, current_path)}
    end
  end

  defp subscribe_to_accounts(accounts) do
    Enum.each(accounts, &PubSub.subscribe_account/1)
  end

  defp page_title_for_action(live_action, workspace) do
    case live_action do
      :budget -> "Budget - #{workspace.name}"
      :reports -> "Reports - #{workspace.name}"
      :accounts -> "Accounts - #{workspace.name}"
    end
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:updated, %Workspace{external_id: external_id} = workspace},
        %{assigns: %{workspace: %{external_id: external_id}}} = socket
      ) do
    {:noreply,
     socket
     |> assign(:workspace, workspace)
     |> assign(:page_title, page_title_for_action(socket.assigns.live_action, workspace))}
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

  # Account event handlers
  def handle_info({:created, %Account{} = account}, socket) do
    PubSub.subscribe_account(account)
    accounts = [account | socket.assigns.accounts]
    {:noreply, assign(socket, :accounts, accounts)}
  end

  def handle_info({:updated, %Account{} = account}, socket) do
    accounts =
      Enum.map(socket.assigns.accounts, fn
        %{id: id} when id == account.id -> account
        existing -> existing
      end)

    {:noreply, assign(socket, :accounts, accounts)}
  end

  def handle_info({:deleted, %Account{} = account}, socket) do
    accounts = Enum.reject(socket.assigns.accounts, &(&1.id == account.id))
    {:noreply, assign(socket, :accounts, accounts)}
  end

  def handle_info({:closed, %Account{} = account}, socket) do
    accounts =
      Enum.map(socket.assigns.accounts, fn
        %{id: id} when id == account.id -> account
        existing -> existing
      end)

    {:noreply, assign(socket, :accounts, accounts)}
  end

  # Forward category/envelope events to BudgetComponent
  def handle_info({:category_repositioned, _category}, socket) do
    send_update(BudgetComponent, id: "budget-component", action: :category_repositioned)
    {:noreply, socket}
  end

  def handle_info({:category_created, _category}, socket) do
    send_update(BudgetComponent, id: "budget-component", action: :category_created)
    {:noreply, socket}
  end

  def handle_info({:category_updated, _category}, socket) do
    send_update(BudgetComponent, id: "budget-component", action: :category_updated)
    {:noreply, socket}
  end

  def handle_info({:category_deleted, _category}, socket) do
    send_update(BudgetComponent, id: "budget-component", action: :category_deleted)
    {:noreply, socket}
  end

  def handle_info({:envelope_repositioned, %{category_id: _category_id} = data}, socket) do
    send_update(BudgetComponent, id: "budget-component", action: :envelope_repositioned, data: data)
    {:noreply, socket}
  end

  def handle_info({:envelope_created, _envelope}, socket) do
    send_update(BudgetComponent, id: "budget-component", action: :envelope_created)
    {:noreply, socket}
  end

  def handle_info({:envelope_updated, _envelope}, socket) do
    send_update(BudgetComponent, id: "budget-component", action: :envelope_updated)
    {:noreply, socket}
  end

  def handle_info({:envelope_deleted, _envelope}, socket) do
    send_update(BudgetComponent, id: "budget-component", action: :envelope_deleted)
    {:noreply, socket}
  end

  def handle_info({:envelope_removed, %{category_id: _category_id} = data}, socket) do
    send_update(BudgetComponent, id: "budget-component", action: :envelope_removed, data: data)
    {:noreply, socket}
  end

  # Handle action messages (for testing)
  def handle_info({:delete_category, %{"id" => _external_id} = params}, socket) do
    send_update(BudgetComponent, id: "budget-component", action: :delete_category, params: params)
    {:noreply, socket}
  end

  def handle_info({:delete_envelope, %{"id" => _external_id} = params}, socket) do
    send_update(BudgetComponent, id: "budget-component", action: :delete_envelope, params: params)
    {:noreply, socket}
  end

  def handle_info({:reposition_category, %{"category_id" => _category_id} = params}, socket) do
    send_update(BudgetComponent, id: "budget-component", action: :reposition_category, params: params)
    {:noreply, socket}
  end

  def handle_info({:reposition_envelope, %{"envelope_id" => _envelope_id} = params}, socket) do
    send_update(BudgetComponent, id: "budget-component", action: :reposition_envelope, params: params)
    {:noreply, socket}
  end

  # Handle flash messages from child components
  def handle_info({:put_flash, type, message}, socket) do
    {:noreply, put_flash(socket, type, message)}
  end

  # Forward drag-and-drop events to BudgetComponent
  @impl Phoenix.LiveView
  def handle_event("reposition_envelope", params, socket) do
    send_update(BudgetComponent, id: "budget-component", action: :reposition_envelope, params: params)
    {:noreply, socket}
  end

  # Forward delete category event to BudgetComponent
  @impl Phoenix.LiveView
  def handle_event("delete_category", params, socket) do
    send_update(BudgetComponent, id: "budget-component", action: :delete_category, params: params)
    {:noreply, socket}
  end

  # Forward category repositioning event to BudgetComponent
  @impl Phoenix.LiveView
  def handle_event("reposition_category", params, socket) do
    send_update(BudgetComponent, id: "budget-component", action: :reposition_category, params: params)
    {:noreply, socket}
  end

  # Forward delete envelope event to BudgetComponent
  @impl Phoenix.LiveView
  def handle_event("delete_envelope", params, socket) do
    send_update(BudgetComponent, id: "budget-component", action: :delete_envelope, params: params)
    {:noreply, socket}
  end
end
