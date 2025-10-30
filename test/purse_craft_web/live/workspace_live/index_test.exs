defmodule PurseCraftWeb.WorkspaceLive.IndexTest do
  use PurseCraftWeb.ConnCase, async: true

  import Mimic
  import Phoenix.LiveViewTest

  alias PurseCraft.Core
  alias PurseCraft.CoreFactory
  alias PurseCraft.PubSub
  alias PurseCraft.Repo

  setup :register_and_log_in_user

  describe "List Workspaces" do
    test "returns all scoped workspaces", %{conn: conn, user: user} do
      stub(PubSub, :subscribe_user_workspaces, fn _scope -> :ok end)

      workspace = CoreFactory.insert(:workspace, name: "Workspace 1")
      CoreFactory.insert(:workspace, name: "Workspace 2")
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id)

      {:ok, _index_live, html} = live(conn, ~p"/workspaces")

      assert html =~ "Listing Workspaces"
      assert html =~ "Workspace 1"
      refute html =~ "Workspace 2"

      verify!()
    end
  end

  describe "Create Workspace" do
    test "with valid data creates new workspace", %{conn: conn} do
      stub(PubSub, :subscribe_user_workspaces, fn _scope -> :ok end)

      attrs = %{
        name: "Some Workspace"
      }

      {:ok, index_live, _html} = live(conn, ~p"/workspaces")

      assert {:ok, form_live, _html} =
               index_live
               |> element("a", "New Workspace")
               |> render_click()
               |> follow_redirect(conn, ~p"/workspaces/new")

      assert render(form_live) =~ "New Workspace"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#workspace-form", workspace: attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/workspaces")

      html = render(index_live)
      assert html =~ "Workspace created successfully"
      assert html =~ "Some Workspace"

      verify!()
    end

    test "with blank name returns error", %{conn: conn} do
      attrs = %{
        name: ""
      }

      {:ok, index_live, _html} = live(conn, ~p"/workspaces")

      assert {:ok, form_live, _html} =
               index_live
               |> element("a", "New Workspace")
               |> render_click()
               |> follow_redirect(conn, ~p"/workspaces/new")

      assert form_live
             |> form("#workspace-form", workspace: attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert form_live
             |> form("#workspace-form", workspace: attrs)
             |> render_submit() =~ "can&#39;t be blank"
    end
  end

  describe "Update Workspace" do
    test "with owner role and valid data updates workspace", %{conn: conn, user: user} do
      workspace = CoreFactory.insert(:workspace, name: "Workspace 1")
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      attrs = %{
        name: "Updated Workspace"
      }

      {:ok, index_live, _html} = live(conn, ~p"/workspaces")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#workspaces-#{workspace.external_id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/workspaces/#{workspace.external_id}/edit")

      assert render(form_live) =~ "Edit Workspace"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#workspace-form", workspace: attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/workspaces")

      html = render(index_live)
      assert html =~ "Workspace updated successfully"
      assert html =~ "Updated Workspace"
      refute html =~ "Workspace 1"
    end

    test "with blank name returns error", %{conn: conn, user: user} do
      workspace = CoreFactory.insert(:workspace, name: "Workspace 1")
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      attrs = %{
        name: ""
      }

      {:ok, index_live, _html} = live(conn, ~p"/workspaces")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#workspaces-#{workspace.external_id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/workspaces/#{workspace.external_id}/edit")

      assert render(form_live) =~ "Edit Workspace"

      assert form_live
             |> form("#workspace-form", workspace: attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert form_live
             |> form("#workspace-form", workspace: attrs)
             |> render_submit() =~ "can&#39;t be blank"
    end
  end

  describe "Delete Workspace" do
    test "deleting non-existent workspace returns flash error", %{conn: conn} do
      stub(Core, :fetch_workspace_by_external_id, fn _scope, _id, _opts ->
        {:error, :not_found}
      end)

      {:ok, view, _html} = live(conn, ~p"/workspaces")

      result = render_hook(view, "delete", %{"external_id" => Ecto.UUID.generate()})

      assert has_element?(view, "#flash-error")
      assert result =~ "flash-error"

      verify!()
    end

    test "with unauthorized scope returns flash error", %{conn: conn, user: user} do
      workspace = CoreFactory.insert(:workspace)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)

      {:ok, view, _html} = live(conn, ~p"/workspaces")

      render_hook(view, "delete", %{"external_id" => workspace.external_id})

      assert has_element?(view, "#flash-error")
      assert render(view) =~ "Failed to delete workspace"
    end

    test "handles error when workspace deletion fails", %{conn: conn, user: user} do
      workspace = CoreFactory.insert(:workspace)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      stub(Core, :delete_workspace, fn _scope, _workspace ->
        {:error, :some_error}
      end)

      {:ok, view, _html} = live(conn, ~p"/workspaces")

      render_hook(view, "delete", %{"external_id" => workspace.external_id})

      assert has_element?(view, "#flash-error")
      assert render(view) =~ "Failed to delete workspace"

      verify!()
    end

    test "with owner role and associated workspace deletes workspace in listing", %{conn: conn, user: user} do
      workspace = CoreFactory.insert(:workspace)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      {:ok, index_live, _html} = live(conn, ~p"/workspaces")

      assert index_live
             |> element("#workspaces-#{workspace.external_id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#workspaces-#{workspace.external_id}")
    end
  end

  describe "PubSub Workspace Update" do
    test "updates to the latest value of the workspace", %{conn: conn, scope: scope, user: user} do
      workspace = CoreFactory.insert(:workspace, name: "My Awesome Budget")
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      {:ok, index_live, html} = live(conn, ~p"/workspaces")

      assert html =~ "Listing Workspaces"
      assert html =~ "My Awesome Budget"

      {:ok, updated_workspace} =
        workspace
        |> Ecto.Changeset.change(name: "Updated via PubSub")
        |> Repo.update()

      PubSub.broadcast_user_workspace(scope, {:updated, updated_workspace})

      updated_html = render(index_live)
      assert updated_html =~ "Updated via PubSub"
      refute updated_html =~ "My Awesome Budget"
    end
  end

  describe "PubSub Workspace Delete" do
    test "deletions remove workspace from listing", %{conn: conn, scope: scope, user: user} do
      workspace = CoreFactory.insert(:workspace, name: "My Awesome Budget")
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      {:ok, index_live, html} = live(conn, ~p"/workspaces")

      assert html =~ "My Awesome Budget"

      {:ok, deleted_workspace} = Repo.delete(workspace)
      PubSub.broadcast_user_workspace(scope, {:deleted, deleted_workspace})

      updated_html = render(index_live)
      refute updated_html =~ "My Awesome Budget"
    end
  end
end
