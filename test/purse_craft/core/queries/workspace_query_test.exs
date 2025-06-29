defmodule PurseCraft.Core.Queries.WorkspaceQueryTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Core.Queries.WorkspaceQuery
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Core.Schemas.WorkspaceUser

  describe "by_user/1" do
    test "creates a query with join and filter by user_id" do
      user_id = 123
      query = WorkspaceQuery.by_user(user_id)

      assert query.from.source == {"workspaces", Workspace}

      assert length(query.joins) == 1
      [join] = query.joins
      assert join.source == {nil, WorkspaceUser}

      assert length(query.wheres) == 1
      [where_clause] = query.wheres
      assert where_clause.params == [{user_id, {1, :user_id}}]
    end
  end

  describe "by_external_id/1" do
    test "creates a query filtered by external_id" do
      external_id = "test-uuid-123"
      query = WorkspaceQuery.by_external_id(external_id)

      assert query.from.source == {"workspaces", Workspace}

      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{external_id, {0, :external_id}}]
    end
  end
end
