defmodule PurseCraftWeb.WorkspaceLive.Components.Sidebar do
  @moduledoc false
  use PurseCraftWeb, :live_component

  alias Phoenix.LiveView.JS
  alias PurseCraftWeb.Components.UI.Core.Icon
  alias PurseCraftWeb.WorkspaceLive.Components.AccountSection

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, visible: false)}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    grouped_accounts =
      assigns
      |> Map.get(:accounts, [])
      |> AccountSection.group_accounts_by_type()

    socket =
      socket
      |> assign(assigns)
      |> assign(:cash_accounts, grouped_accounts.cash)
      |> assign(:credit_accounts, grouped_accounts.credit)
      |> assign(:loan_accounts, grouped_accounts.loans)
      |> assign(:tracking_accounts, grouped_accounts.tracking)

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("toggle", _params, socket) do
    {:noreply, assign(socket, visible: !socket.assigns.visible)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <div
        id="mobile-sidebar-overlay"
        class={"fixed inset-0 bg-black/50 z-40 lg:hidden #{if @visible, do: "", else: "hidden"}"}
        phx-click={JS.push("toggle", target: @myself)}
      >
      </div>

      <aside
        id="sidebar-container"
        class={"w-[280px] flex-shrink-0 border-r border-base-300 bg-base-200 overflow-y-auto flex flex-col fixed lg:static h-full z-50 transition-transform duration-300 ease-in-out shadow-lg #{if @visible, do: "translate-x-0", else: "-translate-x-full lg:translate-x-0"}"}
      >
        <div class="p-4 flex-grow">
          <div class="flex items-center justify-between mb-6">
            <a href="/" class="flex items-center gap-2">
              <img src={~p"/images/logo.svg"} width="30" alt="PurseCraft Logo" />
              <span class="font-bold text-lg">PurseCraft</span>
            </a>
          </div>

          <div class="mb-6">
            <select class="select select-bordered w-full">
              <option>My Budget</option>
              <option>Family Budget</option>
              <option>+ Create New Budget</option>
            </select>
          </div>

          <nav class="space-y-1 mb-6">
            <.sidebar_link
              current_path={@current_path}
              path={get_workspace_path(@current_path, "budget")}
              icon="hero-banknotes"
              label="Budget"
            />
            <.sidebar_link
              current_path={@current_path}
              path={get_workspace_path(@current_path, "reports")}
              icon="hero-chart-bar"
              label="Reports"
            />
            <.sidebar_link
              current_path={@current_path}
              path={get_workspace_path(@current_path, "accounts")}
              icon="hero-credit-card"
              label="All Accounts"
            />
          </nav>

          <div class="space-y-4">
            <AccountSection.account_section
              :if={@cash_accounts != []}
              id="cash-accounts"
              title="CASH"
              accounts={@cash_accounts}
              current_path={@current_path}
              total="$0.00"
            />

            <AccountSection.account_section
              :if={@credit_accounts != []}
              id="credit-accounts"
              title="CREDIT"
              accounts={@credit_accounts}
              current_path={@current_path}
              total="$0.00"
            />

            <AccountSection.account_section
              :if={@loan_accounts != []}
              id="loan-accounts"
              title="LOANS"
              accounts={@loan_accounts}
              current_path={@current_path}
              total="$0.00"
            />

            <AccountSection.account_section
              :if={@tracking_accounts != []}
              id="tracking-accounts"
              title="TRACKING"
              accounts={@tracking_accounts}
              current_path={@current_path}
              total="$0.00"
            />

            <div class="mt-1 px-2">
              <.link
                href={get_workspace_path(@current_path, "accounts/new")}
                class="text-xs flex items-center gap-1 text-base-content/70 hover:text-base-content"
              >
                <Icon.render name="hero-plus-small" class="h-3 w-3" />
                <span>Add Account</span>
              </.link>
            </div>
          </div>
        </div>

        <div class="border-t border-base-300 p-4 sticky bottom-0 bg-base-200">
          <div class="flex items-center gap-3 mb-3">
            <div class="avatar avatar-placeholder">
              <div class="bg-primary text-primary-content w-10 rounded-full">
                <span class="text-xl">
                  {String.at(@current_scope.user.email, 0) |> String.upcase()}
                </span>
              </div>
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium truncate">{@current_scope.user.email}</p>
              <.link
                href={~p"/users/settings"}
                class="text-xs text-base-content/70 hover:text-base-content"
              >
                Settings
              </.link>
            </div>
            <.link
              href={~p"/users/log-out"}
              method="delete"
              class="btn btn-ghost btn-sm"
              aria-label="Log out"
            >
              <Icon.render name="hero-arrow-right-on-rectangle" class="h-5 w-5" />
            </.link>
          </div>

          <div class="flex justify-center">
            <PurseCraftWeb.Layouts.theme_toggle />
          </div>
        </div>
      </aside>

      <div class="lg:hidden fixed top-4 left-4 z-30">
        <button
          class="btn btn-circle btn-ghost bg-base-100/80 shadow-md"
          phx-click={JS.push("toggle", target: @myself)}
          aria-label="Toggle menu"
        >
          <Icon.render name="hero-bars-3" class="h-6 w-6" />
        </button>
      </div>
    </div>
    """
  end

  attr :current_path, :string, required: true
  attr :path, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true

  defp sidebar_link(assigns) do
    active =
      String.starts_with?(assigns.current_path, assigns.path) or
        (assigns.label == "Budget" and String.contains?(assigns.current_path, "/budget")) or
        (assigns.label == "Reports" and String.contains?(assigns.current_path, "/reports")) or
        (assigns.label == "All Accounts" and String.contains?(assigns.current_path, "/accounts"))

    assigns = assign(assigns, :active, active)

    ~H"""
    <.link
      patch={@path}
      class={"flex items-center px-3 py-2 text-sm rounded-lg #{if @active, do: "bg-primary text-primary-content", else: "text-base-content hover:bg-base-300"}"}
    >
      <Icon.render name={@icon} class="mr-3 h-5 w-5" />
      {@label}
    </.link>
    """
  end

  defp get_workspace_path(current_path, page_name) do
    case Regex.run(~r"/workspaces/([a-zA-Z0-9-]+)", current_path) do
      [_match, external_id] ->
        "/workspaces/#{external_id}/#{page_name}"

      # coveralls-ignore-start
      _no_match ->
        "/workspaces"
        # coveralls-ignore-stop
    end
  end
end
