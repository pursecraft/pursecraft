defmodule PurseCraftWeb.Components.UI.Budgeting.Sidebar do
  @moduledoc """
  Sidebar component for the budgeting layout.
  """
  use PurseCraftWeb, :live_component

  alias Phoenix.LiveView.JS
  alias PurseCraftWeb.Components.UI.Budgeting.Icon

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, visible: false)}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
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
              path={get_book_path(@current_path, "budget")}
              icon="hero-banknotes"
              label="Budget"
            />
            <.sidebar_link
              current_path={@current_path}
              path={get_book_path(@current_path, "reports")}
              icon="hero-chart-bar"
              label="Reports"
            />
            <.sidebar_link
              current_path={@current_path}
              path={get_book_path(@current_path, "accounts")}
              icon="hero-credit-card"
              label="All Accounts"
            />
          </nav>

          <div class="space-y-4">
            <div class="space-y-1">
              <div class="flex justify-between items-center px-2 py-1">
                <h3 class="text-xs font-semibold text-base-content/70">BUDGET ACCOUNTS</h3>
                <span class="text-xs font-medium">$5,240.82</span>
              </div>
              <ul class="text-sm">
                <li>
                  <.link
                    href={get_book_path(@current_path, "accounts")}
                    class="flex justify-between py-1 px-2 hover:bg-base-300 rounded-lg"
                  >
                    <span>Checking</span>
                    <span>$3,240.82</span>
                  </.link>
                </li>
                <li>
                  <.link
                    href={get_book_path(@current_path, "accounts")}
                    class="flex justify-between py-1 px-2 hover:bg-base-300 rounded-lg"
                  >
                    <span>Savings</span>
                    <span>$2,000.00</span>
                  </.link>
                </li>
              </ul>
            </div>

            <div class="space-y-1">
              <div class="flex justify-between items-center px-2 py-1">
                <h3 class="text-xs font-semibold text-base-content/70">TRACKING ACCOUNTS</h3>
                <span class="text-xs font-medium">$32,150.00</span>
              </div>
              <ul class="text-sm">
                <li>
                  <.link
                    href={get_book_path(@current_path, "accounts")}
                    class="flex justify-between py-1 px-2 hover:bg-base-300 rounded-lg"
                  >
                    <span>Investment</span>
                    <span>$25,150.00</span>
                  </.link>
                </li>
                <li>
                  <.link
                    href={get_book_path(@current_path, "accounts")}
                    class="flex justify-between py-1 px-2 hover:bg-base-300 rounded-lg"
                  >
                    <span>401(k)</span>
                    <span>$7,000.00</span>
                  </.link>
                </li>
              </ul>
            </div>

            <div class="mt-1 px-2">
              <.link
                href={get_book_path(@current_path, "accounts/new")}
                class="text-xs flex items-center gap-1 text-base-content/70 hover:text-base-content"
              >
                <Icon.icon name="hero-plus-small" class="h-3 w-3" />
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
              <Icon.icon name="hero-arrow-right-on-rectangle" class="h-5 w-5" />
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
          <Icon.icon name="hero-bars-3" class="h-6 w-6" />
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
      href={@path}
      class={"flex items-center px-3 py-2 text-sm rounded-lg #{if @active, do: "bg-primary text-primary-content", else: "text-base-content hover:bg-base-300"}"}
    >
      <Icon.icon name={@icon} class="mr-3 h-5 w-5" />
      {@label}
    </.link>
    """
  end

  defp get_book_path(current_path, page_name) do
    case Regex.run(~r"/books/([a-zA-Z0-9-]+)", current_path) do
      [_match, external_id] ->
        "/books/#{external_id}/#{page_name}"

      # coveralls-ignore-start
      _no_match ->
        "/books"
        # coveralls-ignore-stop
    end
  end
end
