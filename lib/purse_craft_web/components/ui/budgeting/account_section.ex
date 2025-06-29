defmodule PurseCraftWeb.Components.UI.Budgeting.AccountSection do
  @moduledoc """
  Component for displaying accounts grouped by type (budget vs tracking) in the sidebar.
  """

  use PurseCraftWeb, :html

  @type account :: %{
          name: String.t(),
          account_type: String.t(),
          external_id: String.t(),
          closed_at: DateTime.t() | nil
        }

  @cash_account_types ["checking", "savings", "cash"]
  @credit_account_types ["credit_card", "line_of_credit"]
  @loan_account_types ["mortgage", "auto_loan", "student_loan", "personal_loan", "medical_debt", "other_debt"]
  @tracking_account_types ["asset", "liability"]

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :accounts, :list, default: []
  attr :current_path, :string, required: true
  attr :total, :string, default: "$0.00"

  def account_section(assigns) do
    ~H"""
    <div id={@id} class="space-y-1">
      <div class="flex justify-between items-center px-2 py-1">
        <h3 class="text-xs font-semibold text-base-content/70">{@title}</h3>
        <span class="text-xs font-medium">{@total}</span>
      </div>
      <%= if Enum.empty?(@accounts) do %>
        <div class="px-2 py-2 text-sm text-base-content/50 italic">
          No accounts yet
        </div>
      <% else %>
        <ul class="text-sm">
          <%= for account <- @accounts do %>
            <li>
              <.link
                href={get_account_path(@current_path, account)}
                class="flex justify-between py-1 px-2 hover:bg-base-300 rounded-lg"
              >
                <span>{account.name}</span>
                <span>$0.00</span>
              </.link>
            </li>
          <% end %>
        </ul>
      <% end %>
    </div>
    """
  end

  def group_accounts_by_type(accounts) do
    accounts
    |> Enum.filter(&is_nil(&1.closed_at))
    |> Enum.group_by(&account_group/1)
    |> Map.put_new(:cash, [])
    |> Map.put_new(:credit, [])
    |> Map.put_new(:loans, [])
    |> Map.put_new(:tracking, [])
  end

  defp account_group(account) do
    cond do
      account.account_type in @cash_account_types -> :cash
      account.account_type in @credit_account_types -> :credit
      account.account_type in @loan_account_types -> :loans
      account.account_type in @tracking_account_types -> :tracking
      true -> :tracking
    end
  end

  defp get_account_path(current_path, account) do
    case Regex.run(~r"/workspaces/([a-zA-Z0-9-]+)", current_path) do
      [_match, workspace_external_id] ->
        "/workspaces/#{workspace_external_id}/accounts/#{account.external_id}"

      _no_match ->
        "/workspaces"
    end
  end
end
