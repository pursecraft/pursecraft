defmodule PurseCraftWeb.ReportsLive.IndexTest do
  use PurseCraftWeb.ConnCase, async: true

  import Mimic
  import Phoenix.LiveViewTest

  alias PurseCraft.CoreFactory

  setup :register_and_log_in_user

  setup %{user: user} do
    workspace = CoreFactory.insert(:workspace, name: "Test Reports Workspace")
    CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
    %{workspace: workspace}
  end

  describe "Reports page" do
    test "renders reports page elements", %{conn: conn, workspace: workspace} do
      {:ok, _view, html} = live(conn, ~p"/workspaces/#{workspace.external_id}/reports")

      assert html =~ "Reports - #{workspace.name}"
      assert html =~ "Spending Trends"
      assert html =~ "Top Categories"
      assert html =~ "Income vs Spending"
    end

    test "has functioning sidebar links", %{conn: conn, workspace: workspace} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/reports")

      # Check sidebar links are present
      assert has_element?(view, "a", "Budget")
      assert has_element?(view, "a", "Reports")
      assert has_element?(view, "a", "All Accounts")

      # The Reports link should be highlighted as active
      reports_link = element(view, "a", "Reports")
      assert render(reports_link) =~ "bg-primary"
    end

    test "renders user email in sidebar", %{conn: conn, user: user, workspace: workspace} do
      {:ok, _view, html} = live(conn, ~p"/workspaces/#{workspace.external_id}/reports")

      assert html =~ user.email
    end

    test "shows export button", %{conn: conn, workspace: workspace} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/reports")

      assert has_element?(view, "button", "Export")
    end

    test "shows chart placeholders", %{conn: conn, workspace: workspace} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/reports")

      assert has_element?(view, "p", "Chart visualization will be implemented here")
      assert has_element?(view, "p", "Pie chart will be implemented here")
      assert has_element?(view, "p", "Bar chart will be implemented here")
    end

    test "verifies current_path is set correctly", %{conn: conn, workspace: workspace} do
      {:ok, view, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}/reports")

      assert render(view) =~ "/workspaces/#{workspace.external_id}/reports"

      assert page_title(view) =~ "Reports - #{workspace.name}"
    end
  end

  describe "Error handling" do
    test "redirects to workspaces page when workspace doesn't exist with not_found error", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()

      stub(PurseCraft.Core.Policy, :authorize, fn :workspace_read, _scope, _workspace ->
        :ok
      end)

      assert {:error, {:live_redirect, %{to: "/workspaces", flash: %{"error" => "Workspace not found"}}}} =
               live(conn, ~p"/workspaces/#{non_existent_id}/reports")
    end

    test "redirects to workspaces page when workspace doesn't exist", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()

      assert {:error,
              {:live_redirect, %{to: "/workspaces", flash: %{"error" => "You don't have access to this workspace"}}}} =
               live(conn, ~p"/workspaces/#{non_existent_id}/reports")
    end

    test "redirects to workspaces page when unauthorized", %{conn: conn} do
      workspace = CoreFactory.insert(:workspace, name: "Someone Else's Budget")

      assert {:error,
              {:live_redirect, %{to: "/workspaces", flash: %{"error" => "You don't have access to this workspace"}}}} =
               live(conn, ~p"/workspaces/#{workspace.external_id}/reports")
    end
  end
end
