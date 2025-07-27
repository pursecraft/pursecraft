defmodule PurseCraft.Search.Queries.SearchTokenQueryTest do
  use ExUnit.Case, async: true

  alias PurseCraft.Search.Queries.SearchTokenQuery
  alias PurseCraft.Search.Schemas.SearchToken

  describe "by_entity_id/1,2" do
    test "creates query with correct structure using single arity" do
      query = SearchTokenQuery.by_entity_id(123)

      assert query.from.source == {"search_tokens", SearchToken}
      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{123, {0, :entity_id}}]
    end

    test "adds filter to existing query using dual arity" do
      base_query = SearchTokenQuery.by_workspace_id(1)
      query = SearchTokenQuery.by_entity_id(base_query, 123)

      assert query.from.source == {"search_tokens", SearchToken}
      assert length(query.wheres) == 2

      # Verify both where clauses are present
      where_params = Enum.flat_map(query.wheres, & &1.params)
      assert {1, {0, :workspace_id}} in where_params
      assert {123, {0, :entity_id}} in where_params
    end
  end

  describe "by_entity/2,3" do
    test "creates query filtering by entity type and ID using single arity" do
      query = SearchTokenQuery.by_entity("account", 123)

      assert query.from.source == {"search_tokens", SearchToken}
      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{"account", {0, :entity_type}}, {123, {0, :entity_id}}]
    end

    test "adds entity filter to existing query using dual arity" do
      base_query = SearchTokenQuery.by_workspace_id(1)
      query = SearchTokenQuery.by_entity(base_query, "category", 456)

      assert query.from.source == {"search_tokens", SearchToken}
      assert length(query.wheres) == 2

      where_params = Enum.flat_map(query.wheres, & &1.params)
      assert {1, {0, :workspace_id}} in where_params
      assert {"category", {0, :entity_type}} in where_params
      assert {456, {0, :entity_id}} in where_params
    end
  end

  describe "by_entity_type/1,2" do
    test "creates query filtering by entity type using single arity" do
      query = SearchTokenQuery.by_entity_type("account")

      assert query.from.source == {"search_tokens", SearchToken}
      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{"account", {0, :entity_type}}]
    end

    test "adds entity type filter to existing query using dual arity" do
      base_query = SearchTokenQuery.by_workspace_id(1)
      query = SearchTokenQuery.by_entity_type(base_query, "category")

      assert query.from.source == {"search_tokens", SearchToken}
      assert length(query.wheres) == 2

      where_params = Enum.flat_map(query.wheres, & &1.params)
      assert {1, {0, :workspace_id}} in where_params
      assert {"category", {0, :entity_type}} in where_params
    end
  end

  describe "by_entity_types/1,2" do
    test "creates query filtering by multiple entity types using single arity" do
      query = SearchTokenQuery.by_entity_types(["account", "category"])

      assert query.from.source == {"search_tokens", SearchToken}
      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{["account", "category"], {:in, {0, :entity_type}}}]
    end

    test "adds entity types filter to existing query using dual arity" do
      base_query = SearchTokenQuery.by_workspace_id(1)
      query = SearchTokenQuery.by_entity_types(base_query, ["envelope", "payee"])

      assert query.from.source == {"search_tokens", SearchToken}
      assert length(query.wheres) == 2

      where_params = Enum.flat_map(query.wheres, & &1.params)
      assert {1, {0, :workspace_id}} in where_params
      assert {["envelope", "payee"], {:in, {0, :entity_type}}} in where_params
    end
  end

  describe "by_field_name/1,2" do
    test "creates query filtering by field name using single arity" do
      query = SearchTokenQuery.by_field_name("name")

      assert query.from.source == {"search_tokens", SearchToken}
      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{"name", {0, :field_name}}]
    end

    test "adds field name filter to existing query using dual arity" do
      base_query = SearchTokenQuery.by_entity_type("account")
      query = SearchTokenQuery.by_field_name(base_query, "description")

      assert query.from.source == {"search_tokens", SearchToken}
      assert length(query.wheres) == 2

      where_params = Enum.flat_map(query.wheres, & &1.params)
      assert {"account", {0, :entity_type}} in where_params
      assert {"description", {0, :field_name}} in where_params
    end
  end

  describe "by_tokens/1,2" do
    test "creates query filtering by token hashes using single arity" do
      query = SearchTokenQuery.by_tokens(["hel", "wor"])

      assert query.from.source == {"search_tokens", SearchToken}
      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{["hel", "wor"], {:in, {0, :token_hash}}}]
    end

    test "adds token filter to existing query using dual arity" do
      base_query = SearchTokenQuery.by_workspace_id(1)
      query = SearchTokenQuery.by_tokens(base_query, ["abc", "xyz"])

      assert query.from.source == {"search_tokens", SearchToken}
      assert length(query.wheres) == 2

      where_params = Enum.flat_map(query.wheres, & &1.params)
      assert {1, {0, :workspace_id}} in where_params
      assert {["abc", "xyz"], {:in, {0, :token_hash}}} in where_params
    end
  end

  describe "by_workspace_id/1,2" do
    test "creates query filtering by workspace ID using single arity" do
      query = SearchTokenQuery.by_workspace_id(123)

      assert query.from.source == {"search_tokens", SearchToken}
      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{123, {0, :workspace_id}}]
    end

    test "adds workspace filter to existing query using dual arity" do
      base_query = SearchTokenQuery.by_entity_type("account")
      query = SearchTokenQuery.by_workspace_id(base_query, 456)

      assert query.from.source == {"search_tokens", SearchToken}
      assert length(query.wheres) == 2

      where_params = Enum.flat_map(query.wheres, & &1.params)
      assert {"account", {0, :entity_type}} in where_params
      assert {456, {0, :workspace_id}} in where_params
    end
  end

  describe "group_by_entity/0,1" do
    test "creates query with group by and select using single arity" do
      query = SearchTokenQuery.group_by_entity()

      assert query.from.source == {"search_tokens", SearchToken}
      assert length(query.group_bys) == 1

      [group_by] = query.group_bys
      assert length(group_by.expr) == 2

      # Check select structure - it's a {:%{}, [], [field: value, ...]} tuple
      assert elem(query.select.expr, 0) == :%{}
      select_fields = elem(query.select.expr, 2)
      assert Keyword.has_key?(select_fields, :entity_type)
      assert Keyword.has_key?(select_fields, :entity_id)
      assert Keyword.has_key?(select_fields, :match_count)
    end

    test "adds group by to existing query using dual arity" do
      base_query = SearchTokenQuery.by_workspace_id(1)
      query = SearchTokenQuery.group_by_entity(base_query)

      assert query.from.source == {"search_tokens", SearchToken}
      assert length(query.wheres) == 1
      assert length(query.group_bys) == 1

      where_params = Enum.flat_map(query.wheres, & &1.params)
      assert {1, {0, :workspace_id}} in where_params
    end
  end

  describe "limit/1,2" do
    test "creates query with limit using single arity" do
      query = SearchTokenQuery.limit(10)

      assert query.from.source == {"search_tokens", SearchToken}
      # Limit expression contains parameter reference
      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{10, :integer}]
    end

    test "adds limit to existing query using dual arity" do
      base_query = SearchTokenQuery.by_workspace_id(1)
      query = SearchTokenQuery.limit(base_query, 5)

      assert query.from.source == {"search_tokens", SearchToken}
      assert length(query.wheres) == 1
      assert query.limit != nil
      assert query.limit.expr == {:^, [], [0]}

      where_params = Enum.flat_map(query.wheres, & &1.params)
      assert {1, {0, :workspace_id}} in where_params
    end
  end

  describe "order_by_match_count/0,1" do
    test "creates query with match count order using single arity" do
      query = SearchTokenQuery.order_by_match_count()

      assert query.from.source == {"search_tokens", SearchToken}
      assert length(query.order_bys) == 1

      [order_by] = query.order_bys
      # Check the order by expression contains descending count
      assert order_by.expr == [desc: {:count, [], [{{:., [], [{:&, [], [0]}, :id]}, [], []}]}]
    end

    test "adds order by to existing query using dual arity" do
      base_query = SearchTokenQuery.by_workspace_id(1)
      query = SearchTokenQuery.order_by_match_count(base_query)

      assert query.from.source == {"search_tokens", SearchToken}
      assert length(query.wheres) == 1
      assert length(query.order_bys) == 1

      where_params = Enum.flat_map(query.wheres, & &1.params)
      assert {1, {0, :workspace_id}} in where_params

      [order_by] = query.order_bys
      # Verify order by expression exists and contains descending sort
      assert is_list(order_by.expr)
      assert length(order_by.expr) == 1
      assert Keyword.has_key?(order_by.expr, :desc)
    end
  end
end
