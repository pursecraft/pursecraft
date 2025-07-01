defmodule PurseCraftWeb.WorkspaceLive.FormTest do
  use PurseCraftWeb.ConnCase, async: true

  import Mimic
  import Phoenix.LiveViewTest

  alias PurseCraft.Core.Policy
  alias PurseCraft.CoreFactory

  setup :register_and_log_in_user

  describe "Edit Workspace Form" do
    test "creating new workspace shows form", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/workspaces/new")

      assert html =~ "New Workspace"
      assert has_element?(view, "form#workspace-form")
    end

    test "handles not_found error in apply_action", %{conn: conn} do
      workspace_id = Ecto.UUID.generate()

      stub(Policy, :authorize, fn _action, _scope, _workspace ->
        :ok
      end)

      assert {:error, {:live_redirect, %{to: "/workspaces", flash: %{"error" => "Workspace not found"}}}} =
               live(conn, ~p"/workspaces/#{workspace_id}/edit")
    end

    test "redirects when workspace doesn't exist with not_found error", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()

      stub(Policy, :authorize, fn _action, _scope, _workspace ->
        :ok
      end)

      assert {:error, {:live_redirect, %{to: "/workspaces", flash: %{"error" => "Workspace not found"}}}} =
               live(conn, ~p"/workspaces/#{non_existent_id}/edit")
    end

    test "redirects when workspace doesn't exist", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()

      assert {:error,
              {:live_redirect, %{to: "/workspaces", flash: %{"error" => "You don't have access to this workspace"}}}} =
               live(conn, ~p"/workspaces/#{non_existent_id}/edit")
    end

    test "redirects when unauthorized", %{conn: conn} do
      workspace = CoreFactory.insert(:workspace, name: "Someone Else's Budget")

      assert {:error,
              {:live_redirect, %{to: "/workspaces", flash: %{"error" => "You don't have access to this workspace"}}}} =
               live(conn, ~p"/workspaces/#{workspace.external_id}/edit")
    end
  end
end
