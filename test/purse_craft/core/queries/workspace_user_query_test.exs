defmodule PurseCraft.Core.Queries.WorkspaceUserQueryTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Core.Queries.WorkspaceUserQuery
  alias PurseCraft.Core.Schemas.WorkspaceUser

  describe "by_workspace_id/1" do
    test "creates a query filtered by workspace_id" do
      workspace_id = 456
      query = WorkspaceUserQuery.by_workspace_id(workspace_id)

      assert query.from.source == {"workspaces_users", WorkspaceUser}

      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{workspace_id, {0, :workspace_id}}]
    end
  end
end
