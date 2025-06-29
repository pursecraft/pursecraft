defmodule PurseCraftWeb.AccountsLive.IndexTest do
  use PurseCraftWeb.ConnCase, async: true

  import Mimic
  import Phoenix.LiveViewTest

  alias PurseCraft.CoreFactory

  setup :register_and_log_in_user

  setup %{user: user} do
    workspace = CoreFactory.insert(:workspace, name: "Test Accounts Workspace")
    CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
    %{workspace: workspace}
  end

  describe "Accounts page" do
    test "renders transactions page elements", %{conn: conn, workspace: workspace} do
      {:ok, _view, html} = live(conn, ~p"/workspaces/#{workspace.external_id}/accounts")

      assert html =~ "All Accounts - #{workspace.name}"
      assert html =~ "Budget Accounts"
      assert html =~ "Tracking Accounts"
      assert html =~ "Net Worth"
      assert html =~ "Recent Transactions"
    end

    test "has functioning sidebar links", %{conn: conn, workspace: workspace} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/accounts")

      # Check sidebar links are present
      assert has_element?(view, "a", "Budget")
      assert has_element?(view, "a", "Reports")
      assert has_element?(view, "a", "All Accounts")

      # The All Accounts link should be highlighted as active
      accounts_link = element(view, "a", "All Accounts")
      assert render(accounts_link) =~ "bg-primary"
    end

    test "renders user email in sidebar", %{conn: conn, user: user, workspace: workspace} do
      {:ok, _view, html} = live(conn, ~p"/workspaces/#{workspace.external_id}/accounts")

      assert html =~ user.email
    end

    test "shows add account and reconcile buttons", %{conn: conn, workspace: workspace} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/accounts")

      assert has_element?(view, "button", "Add Account")
      assert has_element?(view, "button", "Reconcile")
    end

    test "displays account cards", %{conn: conn, workspace: workspace} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/accounts")

      assert has_element?(view, "h4", "Checking")
      assert has_element?(view, "h4", "Savings")
      assert has_element?(view, "h4", "Investment")
      assert has_element?(view, "h4", "401(k)")
    end

    test "shows transaction table", %{conn: conn, workspace: workspace} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/accounts")

      assert has_element?(view, "table")
      assert has_element?(view, "th", "Date")
      assert has_element?(view, "th", "Payee")
      assert has_element?(view, "th", "Category")
      assert has_element?(view, "th", "Amount")
      assert has_element?(view, "th", "Account")

      # Check for specific transaction
      assert has_element?(view, "td", "Grocery Store")
      assert has_element?(view, "td", "Employer")
    end
  end

  describe "Error handling" do
    test "redirects to workspaces page when workspace doesn't exist with not_found error", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()

      stub(PurseCraft.Core.Policy, :authorize, fn :workspace_read, _scope, _workspace ->
        :ok
      end)

      assert {:error, {:live_redirect, %{to: "/workspaces", flash: %{"error" => "Workspace not found"}}}} =
               live(conn, ~p"/workspaces/#{non_existent_id}/accounts")
    end

    test "redirects to workspaces page when workspace doesn't exist", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()

      assert {:error,
              {:live_redirect, %{to: "/workspaces", flash: %{"error" => "You don't have access to this workspace"}}}} =
               live(conn, ~p"/workspaces/#{non_existent_id}/accounts")
    end

    test "redirects to workspaces page when unauthorized", %{conn: conn} do
      workspace = CoreFactory.insert(:workspace, name: "Someone Else's Budget")

      assert {:error,
              {:live_redirect, %{to: "/workspaces", flash: %{"error" => "You don't have access to this workspace"}}}} =
               live(conn, ~p"/workspaces/#{workspace.external_id}/accounts")
    end
  end
end
