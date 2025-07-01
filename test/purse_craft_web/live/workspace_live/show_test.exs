defmodule PurseCraftWeb.WorkspaceLive.ShowTest do
  use PurseCraftWeb.ConnCase, async: true

  import Mimic
  import Phoenix.LiveViewTest

  alias PurseCraft.Core
  alias PurseCraft.CoreFactory
  alias PurseCraft.PubSub
  alias PurseCraft.Repo

  setup :register_and_log_in_user

  describe "Display Workspace" do
    test "with associated workspace (authorized scope) displays workspace", %{conn: conn, user: user} do
      workspace = CoreFactory.insert(:workspace, name: "My Awesome Budget")
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)

      {:ok, _show_live, html} = live(conn, ~p"/workspaces/#{workspace.external_id}")

      assert html =~ "Show Workspace"
      assert html =~ "My Awesome Budget"
    end

    test "redirects to workspaces page when workspace doesn't exist", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()

      assert {:error,
              {:live_redirect, %{to: "/workspaces", flash: %{"error" => "You don't have access to this workspace"}}}} =
               live(conn, ~p"/workspaces/#{non_existent_id}")
    end

    test "redirects to workspaces page with not_found message when workspace doesn't exist with bypassed authorization",
         %{
           conn: conn
         } do
      non_existent_id = Ecto.UUID.generate()

      stub(PurseCraft.Core.Policy, :authorize, fn _action, _scope, _workspace ->
        :ok
      end)

      assert {:error, {:live_redirect, %{to: "/workspaces", flash: %{"error" => "Workspace not found"}}}} =
               live(conn, ~p"/workspaces/#{non_existent_id}")
    end

    test "redirects to workspaces page when unauthorized", %{conn: conn} do
      workspace = CoreFactory.insert(:workspace, name: "Someone Else's Budget")

      assert {:error,
              {:live_redirect, %{to: "/workspaces", flash: %{"error" => "You don't have access to this workspace"}}}} =
               live(conn, ~p"/workspaces/#{workspace.external_id}")
    end
  end

  describe "Update Workspace" do
    test "with associated workspace, owner role, and valid data updates workspace and returns to show", %{
      conn: conn,
      user: user
    } do
      workspace = CoreFactory.insert(:workspace, name: "My Awesome Budget")
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      attrs = %{
        name: "My Spectacular Budget"
      }

      {:ok, show_live, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}")

      assert {:ok, form_live, _html} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/workspaces/#{workspace.external_id}/edit?return_to=show")

      assert render(form_live) =~ "Edit Workspace"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#workspace-form", workspace: attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/workspaces/#{workspace.external_id}")

      html = render(show_live)
      assert html =~ "Workspace updated successfully"
      assert html =~ "My Spectacular Budget"
      refute html =~ "My Awesome Budget"
    end

    test "with associated workspace, owner role, and blank name returns error", %{conn: conn, user: user} do
      workspace = CoreFactory.insert(:workspace, name: "My Awesome Budget")
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      attrs = %{
        name: ""
      }

      {:ok, show_live, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}")

      assert {:ok, form_live, _html} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/workspaces/#{workspace.external_id}/edit?return_to=show")

      assert render(form_live) =~ "Edit Workspace"

      assert form_live
             |> form("#workspace-form", workspace: attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert form_live
             |> form("#workspace-form", workspace: attrs)
             |> render_submit() =~ "can&#39;t be blank"
    end
  end

  describe "PubSub Workspace Update" do
    test "updates to the latest value of the workspace", %{conn: conn, user: user} do
      workspace = CoreFactory.insert(:workspace, name: "My Awesome Budget")
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      {:ok, show_live, html} = live(conn, ~p"/workspaces/#{workspace.external_id}")

      assert html =~ "Show Workspace"
      assert html =~ "My Awesome Budget"

      {:ok, updated_workspace} =
        workspace
        |> Ecto.Changeset.change(name: "Updated via PubSub")
        |> Repo.update()

      PubSub.broadcast_workspace(workspace, {:updated, updated_workspace})

      updated_html = render(show_live)
      assert updated_html =~ "Updated via PubSub"
      refute updated_html =~ "My Awesome Budget"
    end
  end

  describe "PubSub Workspace Delete" do
    test "deletions redirect current viewing users to /workspaces", %{conn: conn, user: user} do
      workspace = CoreFactory.insert(:workspace, name: "My Awesome Budget")
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      {:ok, show_live, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}")

      PubSub.broadcast_workspace(workspace, {:deleted, workspace})

      flash = assert_redirect(show_live, ~p"/workspaces")
      assert flash["error"] == "The current workspace was deleted."
    end
  end

  describe "Workspace retrieval errors" do
    test "handles workspace update with fetch error", %{conn: conn, user: user} do
      workspace = CoreFactory.insert(:workspace, name: "My Awesome Budget")
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      {:ok, show_live, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}")

      stub(Core, :fetch_workspace_by_external_id, fn _scope, external_id, _opts ->
        if external_id == workspace.external_id do
          {:error, :not_found}
        else
          {:error, :unauthorized}
        end
      end)

      rendered = render(show_live)
      assert rendered =~ "My Awesome Budget"

      PubSub.broadcast_workspace(workspace, {:updated, workspace})

      assert render(show_live) =~ "My Awesome Budget"
    end

    test "handles workspace update with non-matching workspace data", %{conn: conn, user: user} do
      workspace = CoreFactory.insert(:workspace, name: "My Awesome Budget")
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      {:ok, show_live, _html} = live(conn, ~p"/workspaces/#{workspace.external_id}")

      different_workspace = CoreFactory.insert(:workspace, name: "Different Workspace")

      PubSub.broadcast_workspace(different_workspace, {:updated, different_workspace})

      assert render(show_live) =~ "My Awesome Budget"
      refute render(show_live) =~ "Different Workspace"
    end
  end
end
