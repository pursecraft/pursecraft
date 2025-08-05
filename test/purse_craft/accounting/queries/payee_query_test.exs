defmodule PurseCraft.Accounting.Queries.PayeeQueryTest do
  use PurseCraft.DataCase, async: true

  import Ecto.Query

  alias PurseCraft.Accounting.Queries.PayeeQuery
  alias PurseCraft.Accounting.Schemas.Payee

  describe "by_workspace_id/1" do
    test "creates a query filtered by workspace_id" do
      workspace_id = 123
      query = PayeeQuery.by_workspace_id(workspace_id)

      assert query.from.source == {"payees", Payee}

      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{workspace_id, {0, :workspace_id}}]
    end
  end

  describe "by_workspace_id/2" do
    test "adds workspace_id filter to existing query" do
      workspace_id = 456
      base_query = from(p in Payee, where: p.name == "Test Payee")

      query = PayeeQuery.by_workspace_id(base_query, workspace_id)

      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {workspace_id, {0, :workspace_id}} in param_values
    end

    test "works with Payee schema directly" do
      workspace_id = 789
      query = PayeeQuery.by_workspace_id(Payee, workspace_id)

      assert query.from.source == {"payees", Payee}
      assert length(query.wheres) == 1
      assert hd(query.wheres).params == [{workspace_id, {0, :workspace_id}}]
    end

    test "preserves other query attributes" do
      base_query =
        from(p in Payee,
          where: p.name == "Test",
          order_by: p.inserted_at,
          limit: 10
        )

      query = PayeeQuery.by_workspace_id(base_query, 123)

      assert query.limit.expr == 10
      assert length(query.order_bys) == 1
      assert length(query.wheres) == 2
    end
  end

  describe "by_external_id/1" do
    test "creates a query filtered by external_id" do
      external_id = Ecto.UUID.generate()
      query = PayeeQuery.by_external_id(external_id)

      assert query.from.source == {"payees", Payee}

      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{external_id, {0, :external_id}}]
    end
  end

  describe "by_external_id/2" do
    test "adds external_id filter to existing query" do
      external_id = Ecto.UUID.generate()
      base_query = from(p in Payee, where: p.workspace_id == 1)

      query = PayeeQuery.by_external_id(base_query, external_id)

      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {external_id, {0, :external_id}} in param_values
    end

    test "works with Payee schema directly" do
      external_id = Ecto.UUID.generate()
      query = PayeeQuery.by_external_id(Payee, external_id)

      assert query.from.source == {"payees", Payee}
      assert length(query.wheres) == 1
      assert hd(query.wheres).params == [{external_id, {0, :external_id}}]
    end

    test "preserves other query attributes" do
      base_query =
        from(p in Payee,
          where: p.workspace_id == 1,
          order_by: p.inserted_at,
          limit: 5
        )

      external_id = Ecto.UUID.generate()
      query = PayeeQuery.by_external_id(base_query, external_id)

      assert query.limit.expr == 5
      assert length(query.order_bys) == 1
      assert length(query.wheres) == 2
    end
  end

  describe "by_name_hash/1" do
    test "creates a query filtered by name_hash" do
      name_hash = "hashed_name_value"
      query = PayeeQuery.by_name_hash(name_hash)

      assert query.from.source == {"payees", Payee}

      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{name_hash, {0, :name_hash}}]
    end
  end

  describe "by_name_hash/2" do
    test "adds name_hash filter to existing query" do
      name_hash = "hashed_name_value"
      base_query = from(p in Payee, where: p.workspace_id == 1)

      query = PayeeQuery.by_name_hash(base_query, name_hash)

      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {name_hash, {0, :name_hash}} in param_values
    end

    test "works with Payee schema directly" do
      name_hash = "hashed_name_value"
      query = PayeeQuery.by_name_hash(Payee, name_hash)

      assert query.from.source == {"payees", Payee}
      assert length(query.wheres) == 1
      assert hd(query.wheres).params == [{name_hash, {0, :name_hash}}]
    end

    test "preserves other query attributes" do
      base_query =
        from(p in Payee,
          where: p.workspace_id == 1,
          order_by: p.name,
          limit: 3
        )

      name_hash = "hashed_name_value"
      query = PayeeQuery.by_name_hash(base_query, name_hash)

      assert query.limit.expr == 3
      assert length(query.order_bys) == 1
      assert length(query.wheres) == 2
    end
  end

  describe "preload_workspace/0" do
    test "creates a query with workspace preload" do
      query = PayeeQuery.preload_workspace()

      assert query.from.source == {"payees", Payee}
      assert query.preloads == [:workspace]
    end
  end

  describe "preload_workspace/1" do
    test "adds workspace preload to existing query" do
      base_query = from(p in Payee, where: p.workspace_id == 1)

      query = PayeeQuery.preload_workspace(base_query)

      assert query.preloads == [:workspace]
      assert length(query.wheres) == 1
    end

    test "works with Payee schema directly" do
      query = PayeeQuery.preload_workspace(Payee)

      assert query.from.source == {"payees", Payee}
      assert query.preloads == [:workspace]
    end

    test "preserves other query attributes" do
      base_query =
        from(p in Payee,
          where: p.workspace_id == 1,
          order_by: p.name,
          limit: 10
        )

      query = PayeeQuery.preload_workspace(base_query)

      assert query.preloads == [:workspace]
      assert query.limit.expr == 10
      assert length(query.order_bys) == 1
      assert length(query.wheres) == 1
    end
  end

  describe "order_by_name/0" do
    test "creates a query ordered by name in ascending order" do
      query = PayeeQuery.order_by_name()

      assert query.from.source == {"payees", Payee}
      assert length(query.order_bys) == 1

      [order_by] = query.order_bys
      assert order_by.expr == [asc: {{:., [], [{:&, [], [0]}, :name]}, [], []}]
    end
  end

  describe "order_by_name/1" do
    test "adds name ordering to existing query" do
      base_query = from(p in Payee, where: p.workspace_id == 1)
      query = PayeeQuery.order_by_name(base_query)

      assert length(query.order_bys) == 1
      [order_by] = query.order_bys
      assert order_by.expr == [asc: {{:., [], [{:&, [], [0]}, :name]}, [], []}]
    end

    test "works with Payee schema directly" do
      query = PayeeQuery.order_by_name(Payee)

      assert query.from.source == {"payees", Payee}
      assert length(query.order_bys) == 1
      [order_by] = query.order_bys
      assert order_by.expr == [asc: {{:., [], [{:&, [], [0]}, :name]}, [], []}]
    end

    test "preserves other query attributes" do
      base_query =
        from(p in Payee,
          where: p.workspace_id == 1,
          limit: 5
        )

      query = PayeeQuery.order_by_name(base_query)

      assert query.limit.expr == 5
      assert length(query.wheres) == 1
      assert length(query.order_bys) == 1
    end
  end

  describe "order_by_recent/0" do
    test "creates a query ordered by inserted_at in descending order" do
      query = PayeeQuery.order_by_recent()

      assert query.from.source == {"payees", Payee}
      assert length(query.order_bys) == 1

      [order_by] = query.order_bys
      assert order_by.expr == [desc: {{:., [], [{:&, [], [0]}, :inserted_at]}, [], []}]
    end
  end

  describe "order_by_recent/1" do
    test "adds recent ordering to existing query" do
      base_query = from(p in Payee, where: p.workspace_id == 1)
      query = PayeeQuery.order_by_recent(base_query)

      assert length(query.order_bys) == 1
      [order_by] = query.order_bys
      assert order_by.expr == [desc: {{:., [], [{:&, [], [0]}, :inserted_at]}, [], []}]
    end

    test "works with Payee schema directly" do
      query = PayeeQuery.order_by_recent(Payee)

      assert query.from.source == {"payees", Payee}
      assert length(query.order_bys) == 1
      [order_by] = query.order_bys
      assert order_by.expr == [desc: {{:., [], [{:&, [], [0]}, :inserted_at]}, [], []}]
    end

    test "preserves other query attributes" do
      base_query =
        from(p in Payee,
          where: p.workspace_id == 1,
          limit: 8
        )

      query = PayeeQuery.order_by_recent(base_query)

      assert query.limit.expr == 8
      assert length(query.wheres) == 1
      assert length(query.order_bys) == 1
    end
  end

  describe "limit/1" do
    test "creates a query with limit" do
      count = 5
      query = PayeeQuery.limit(count)

      assert query.from.source == {"payees", Payee}
      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{5, :integer}]
    end
  end

  describe "limit/2" do
    test "adds limit to existing query" do
      base_query = from(p in Payee, where: p.workspace_id == 1)
      count = 10
      query = PayeeQuery.limit(base_query, count)

      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{10, :integer}]
    end

    test "works with Payee schema directly" do
      count = 3
      query = PayeeQuery.limit(Payee, count)

      assert query.from.source == {"payees", Payee}
      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{3, :integer}]
    end

    test "preserves other query attributes" do
      base_query =
        from(p in Payee,
          where: p.workspace_id == 1,
          order_by: p.name
        )

      count = 7
      query = PayeeQuery.limit(base_query, count)

      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{7, :integer}]
      assert length(query.wheres) == 1
      assert length(query.order_bys) == 1
    end
  end

  describe "query composition" do
    test "functions can be chained together" do
      workspace_id = 123
      external_id = Ecto.UUID.generate()
      name_hash = "test_hash"

      query =
        workspace_id
        |> PayeeQuery.by_workspace_id()
        |> PayeeQuery.by_external_id(external_id)
        |> PayeeQuery.by_name_hash(name_hash)
        |> PayeeQuery.preload_workspace()
        |> PayeeQuery.order_by_name()
        |> PayeeQuery.limit(10)

      assert query.from.source == {"payees", Payee}
      assert length(query.wheres) == 3
      assert query.preloads == [:workspace]
      assert length(query.order_bys) == 1
      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{10, :integer}]

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {workspace_id, {0, :workspace_id}} in param_values
      assert {external_id, {0, :external_id}} in param_values
      assert {name_hash, {0, :name_hash}} in param_values
    end

    test "functions work with arbitrary base queries" do
      base_query = from(p in "payees", select: p.id)
      workspace_id = 456

      query =
        base_query
        |> PayeeQuery.by_workspace_id(workspace_id)
        |> PayeeQuery.order_by_recent()

      assert query.from.source == {"payees", nil}
      assert length(query.wheres) == 1
      assert length(query.order_bys) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{workspace_id, {0, :workspace_id}}]

      [order_by] = query.order_bys
      assert order_by.expr == [desc: {{:., [], [{:&, [], [0]}, :inserted_at]}, [], []}]
    end

    test "dual-arity functions accept other schemas" do
      workspace_id = 789
      name_hash = "other_hash"

      base_query = from(other in "other_table")

      query =
        base_query
        |> PayeeQuery.by_workspace_id(workspace_id)
        |> PayeeQuery.by_name_hash(name_hash)
        |> PayeeQuery.order_by_name()

      assert query.from.source == {"other_table", nil}
      assert length(query.wheres) == 2
      assert length(query.order_bys) == 1

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {workspace_id, {0, :workspace_id}} in param_values
      assert {name_hash, {0, :name_hash}} in param_values
    end
  end
end
