defmodule PurseCraft.Core.Commands.Workspaces.GetWorkspaceByExternalIdTest do
  use PurseCraft.DataCase, async: true
  use Mimic

  alias PurseCraft.Core.Commands.Workspaces.GetWorkspaceByExternalId
  alias PurseCraft.Core.Policy
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

  describe "call!/2" do
    test "with associated workspace (authorized scope) returns workspace" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      workspace = CoreFactory.insert(:workspace)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)

      result = GetWorkspaceByExternalId.call!(scope, workspace.external_id)
      assert result.id == workspace.id
      assert result.external_id == workspace.external_id
      assert result.name == workspace.name
    end

    test "with no associated workspaces (unauthorized scope) raises `LetMe.UnauthorizedError`" do
      assert_raise LetMe.UnauthorizedError, fn ->
        user = IdentityFactory.insert(:user)
        scope = IdentityFactory.build(:scope, user: user)
        workspace = CoreFactory.insert(:workspace)

        GetWorkspaceByExternalId.call!(scope, workspace.external_id)
      end
    end

    test "with non-existent workspace raises `Ecto.NoResultsError`" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      non_existent_id = Ecto.UUID.generate()

      expect(Policy, :authorize!, fn :workspace_read, _scope, _params -> :ok end)

      assert_raise Ecto.NoResultsError, fn ->
        GetWorkspaceByExternalId.call!(scope, non_existent_id)
      end
    end
  end
end
