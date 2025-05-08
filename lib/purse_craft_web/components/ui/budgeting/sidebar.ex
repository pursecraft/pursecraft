defmodule PurseCraftWeb.Components.UI.Budgeting.Sidebar do
  @moduledoc """
  Sidebar component for the budgeting layout.
  """
  use PurseCraftWeb, :html

  attr :current_path, :string, required: true
  attr :current_scope, :map, required: true

  def sidebar(assigns) do
    ~H"""
    <aside class="w-64 flex-shrink-0 border-r border-base-300 bg-base-200 overflow-y-auto flex flex-col">
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

        <nav class="space-y-1">
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
      </div>

      <div class="border-t border-base-300 p-4 sticky bottom-0 bg-base-200">
        <div class="flex items-center gap-3 mb-3">
          <div class="avatar placeholder">
            <div class="bg-primary text-base-100 rounded-full w-10">
              <span>{String.at(@current_scope.user.email, 0) |> String.upcase()}</span>
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
          <form action={~p"/users/log-out"} method="post">
            <input type="hidden" name="_csrf_token" value={get_csrf_token()} />
            <button type="submit" class="btn btn-ghost btn-sm" aria-label="Log out">
              <.icon name="hero-arrow-right-on-rectangle" class="h-5 w-5" />
            </button>
          </form>
        </div>

        <div class="flex justify-center">
          <PurseCraftWeb.Layouts.theme_toggle />
        </div>
      </div>
    </aside>
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
      <.icon name={@icon} class="mr-3 h-5 w-5" />
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
