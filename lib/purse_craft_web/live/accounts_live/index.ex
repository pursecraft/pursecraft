defmodule PurseCraftWeb.AccountsLive.Index do
  @moduledoc false

  use PurseCraftWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "All Accounts")
      |> assign(:current_path, "/accounts")

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.budgeting flash={@flash} current_path={@current_path} current_scope={@current_scope}>
      <div class="space-y-6">
        <div class="flex justify-between items-center">
          <h1 class="text-2xl font-bold">All Accounts</h1>
          <div class="flex gap-2">
            <button class="btn btn-primary">Add Account</button>
            <button class="btn btn-outline">Reconcile</button>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div class="card bg-base-200">
            <div class="card-body p-4">
              <h2 class="card-title text-sm">Budget Accounts</h2>
              <p class="text-2xl font-bold">$5,240.82</p>
            </div>
          </div>
          <div class="card bg-base-200">
            <div class="card-body p-4">
              <h2 class="card-title text-sm">Tracking Accounts</h2>
              <p class="text-2xl font-bold">$32,150.00</p>
            </div>
          </div>
          <div class="card bg-base-200">
            <div class="card-body p-4">
              <h2 class="card-title text-sm">Net Worth</h2>
              <p class="text-2xl font-bold">$37,390.82</p>
            </div>
          </div>
        </div>
        
    <!-- Account Groups -->
        <div class="space-y-6">
          <!-- Budget Accounts -->
          <div class="space-y-2">
            <h3 class="font-bold text-xl">Budget Accounts</h3>

            <.account_card name="Checking" balance="3,240.82" type="Checking" />

            <.account_card name="Savings" balance="2,000.00" type="Savings" />
          </div>
          
    <!-- Tracking Accounts -->
          <div class="space-y-2">
            <h3 class="font-bold text-xl">Tracking Accounts</h3>

            <.account_card name="Investment" balance="25,150.00" type="Investment" />

            <.account_card name="401(k)" balance="7,000.00" type="Retirement" />
          </div>
        </div>
        
    <!-- Recent Transactions -->
        <div class="space-y-4">
          <h3 class="font-bold text-xl">Recent Transactions</h3>

          <div class="overflow-x-auto">
            <table class="table table-zebra w-full">
              <thead>
                <tr>
                  <th>Date</th>
                  <th>Payee</th>
                  <th>Category</th>
                  <th class="text-right">Amount</th>
                  <th class="text-right">Account</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>May 5, 2025</td>
                  <td>Grocery Store</td>
                  <td>Groceries</td>
                  <td class="text-right text-error">-$85.42</td>
                  <td class="text-right">Checking</td>
                </tr>
                <tr>
                  <td>May 4, 2025</td>
                  <td>Coffee Shop</td>
                  <td>Dining Out</td>
                  <td class="text-right text-error">-$4.75</td>
                  <td class="text-right">Checking</td>
                </tr>
                <tr>
                  <td>May 1, 2025</td>
                  <td>Employer</td>
                  <td>Income</td>
                  <td class="text-right text-success">$2,500.00</td>
                  <td class="text-right">Checking</td>
                </tr>
                <tr>
                  <td>Apr 30, 2025</td>
                  <td>Internet Provider</td>
                  <td>Internet</td>
                  <td class="text-right text-error">-$75.00</td>
                  <td class="text-right">Checking</td>
                </tr>
                <tr>
                  <td>Apr 28, 2025</td>
                  <td>Transfer</td>
                  <td>To be budgeted</td>
                  <td class="text-right text-error">-$500.00</td>
                  <td class="text-right">Checking</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </Layouts.budgeting>
    """
  end

  attr :name, :string, required: true
  attr :balance, :string, required: true
  attr :type, :string, required: true

  defp account_card(assigns) do
    ~H"""
    <div class="card bg-base-100 border border-base-300 shadow-sm">
      <div class="card-body p-4">
        <div class="flex justify-between items-center">
          <div>
            <h4 class="font-bold">{@name}</h4>
            <p class="text-xs text-base-content/70">{@type}</p>
          </div>
          <div class="text-xl font-bold">${@balance}</div>
        </div>
      </div>
    </div>
    """
  end
end
