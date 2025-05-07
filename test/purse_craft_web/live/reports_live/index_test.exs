defmodule PurseCraftWeb.ReportsLive.IndexTest do
  use PurseCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias PurseCraftWeb.ReportsLive.Index

  setup :register_and_log_in_user

  describe "Reports page" do
    test "renders reports page elements", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/reports")

      assert html =~ "Reports"
      assert html =~ "Spending Trends"
      assert html =~ "Top Categories"
      assert html =~ "Income vs Spending"
    end

    test "has functioning sidebar links", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/reports")

      # Check sidebar links are present
      assert has_element?(view, "a", "Budget")
      assert has_element?(view, "a", "Reports")
      assert has_element?(view, "a", "All Accounts")

      # The Reports link should be highlighted as active
      reports_link = element(view, "a", "Reports")
      assert render(reports_link) =~ "bg-primary"
    end

    test "renders user email in sidebar", %{conn: conn, user: user} do
      {:ok, _view, html} = live(conn, ~p"/reports")

      assert html =~ user.email
    end

    test "shows export button", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/reports")

      assert has_element?(view, "button", "Export")
    end

    test "shows chart placeholders", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/reports")

      assert has_element?(view, "p", "Chart visualization will be implemented here")
      assert has_element?(view, "p", "Pie chart will be implemented here")
      assert has_element?(view, "p", "Bar chart will be implemented here")
    end

    test "verifies current_path is set correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/reports")

      # This is to test that the mount function is setting current_path correctly
      assert render(view) =~ "/reports"

      # Test page title is set correctly
      assert page_title(view) =~ "Reports"
    end

    test "mount function correctly assigns values to socket" do
      # Create a fresh socket for testing the mount function directly
      socket = %Phoenix.LiveView.Socket{}

      # Call mount function directly
      {:ok, updated_socket} = Index.mount(%{}, %{}, socket)

      # Verify the socket has the correct assigns
      assert updated_socket.assigns.page_title == "Reports"
      assert updated_socket.assigns.current_path == "/reports"
    end
  end
end
