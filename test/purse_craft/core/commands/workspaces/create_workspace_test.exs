defmodule PurseCraft.Core.Commands.Workspaces.CreateWorkspaceTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Core.Commands.Workspaces.CreateWorkspace
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Core.Schemas.WorkspaceUser
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastUserWorkspace
  alias PurseCraft.Repo

  setup do
    user = IdentityFactory.insert(:user)
    scope = IdentityFactory.build(:scope, user: user)

    %{
      user: user,
      scope: scope
    }
  end

  describe "call/2" do
    test "with valid data creates a workspace", %{scope: scope} do
      attrs = %{name: "Test Command Workspace"}

      assert {:ok, %Workspace{} = workspace} = CreateWorkspace.call(scope, attrs)
      assert workspace.name == "Test Command Workspace"

      workspace_user = Repo.get_by(WorkspaceUser, workspace_id: workspace.id)
      assert workspace_user.user_id == scope.user.id
      assert workspace_user.role == :owner
    end

    test "with invalid data returns error changeset", %{scope: scope} do
      attrs = %{name: ""}

      assert {:error, changeset} = CreateWorkspace.call(scope, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with unauthorized scope returns error" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      # This doesn't actually happen in reality since all users are allowed to create
      # `Workspace` records, so we are mocking this response to see if this branch of the
      # business logic actually works.
      stub(PurseCraft.Core.Policy, :authorize, fn :workspace_create, _scope ->
        {:error, :unauthorized}
      end)

      attrs = %{name: "Unauthorized Workspace"}

      assert {:error, :unauthorized} = CreateWorkspace.call(scope, attrs)
    end

    test "Invokes BroadcastUserWorkspace when workspace is created successfully", %{scope: scope} do
      expect(BroadcastUserWorkspace, :call, fn broadcast_scope, {:created, broadcast_workspace} ->
        assert broadcast_scope == scope
        assert broadcast_workspace.name == "Broadcast Test Workspace"
        :ok
      end)

      attrs = %{name: "Broadcast Test Workspace"}

      assert {:ok, %Workspace{}} = CreateWorkspace.call(scope, attrs)

      verify!()
    end
  end
end
