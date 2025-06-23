defmodule PurseCraftWeb.Components.UI.Budgeting.AccountSection do
  @moduledoc """
  Account section component for the budgeting sidebar.
  """
  use Phoenix.Component

  attr :title, :string, required: true
  attr :accounts, :list, required: true
  attr :current_path, :string, required: true

  def account_section(assigns) do
    ~H"""
    <div :if={@accounts != []} class="space-y-1">
      <div class="flex justify-between items-center px-2 py-1">
        <h3 class="text-xs font-semibold text-base-content/70">{@title}</h3>
        <span class="text-xs font-medium">$0.00</span>
      </div>
      <ul class="text-sm">
        <li :for={account <- @accounts}>
          <.link
            href={get_book_path(@current_path, "accounts")}
            class="flex justify-between py-1 px-2 hover:bg-base-300 rounded-lg"
          >
            <span>{account.name}</span>
            <span>$0.00</span>
          </.link>
        </li>
      </ul>
    </div>
    """
  end

  defp get_book_path(current_path, page_name) do
    case Regex.run(~r"/books/([a-zA-Z0-9-]+)", current_path) do
      [_match, external_id] ->
        "/books/#{external_id}/#{page_name}"

      _no_match ->
        "/books"
    end
  end
end