defmodule PurseCraft.Accounting.Queries.TransactionQueryTest do
  use PurseCraft.DataCase, async: true

  import Ecto.Query

  alias PurseCraft.Accounting.Queries.TransactionQuery
  alias PurseCraft.Accounting.Schemas.Transaction

  describe "by_workspace_id/1" do
    test "creates a query filtered by workspace_id" do
      workspace_id = 123
      query = TransactionQuery.by_workspace_id(workspace_id)

      assert query.from.source == {"transactions", Transaction}

      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{workspace_id, {0, :workspace_id}}]
    end
  end

  describe "by_workspace_id/2" do
    test "adds workspace_id filter to existing query" do
      workspace_id = 456
      base_query = from(t in Transaction, where: t.amount > 0)

      query = TransactionQuery.by_workspace_id(base_query, workspace_id)

      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {workspace_id, {0, :workspace_id}} in param_values
    end

    test "works with Transaction schema directly" do
      workspace_id = 789
      query = TransactionQuery.by_workspace_id(Transaction, workspace_id)

      assert query.from.source == {"transactions", Transaction}
      assert length(query.wheres) == 1
      assert hd(query.wheres).params == [{workspace_id, {0, :workspace_id}}]
    end

    test "preserves other query attributes" do
      base_query =
        from(t in Transaction,
          where: t.amount > 0,
          order_by: t.date,
          limit: 10
        )

      query = TransactionQuery.by_workspace_id(base_query, 123)

      assert query.limit.expr == 10
      assert length(query.order_bys) == 1
      assert length(query.wheres) == 2
    end
  end

  describe "by_account_id/1" do
    test "creates a query filtered by account_id" do
      account_id = 123
      query = TransactionQuery.by_account_id(account_id)

      assert query.from.source == {"transactions", Transaction}

      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{account_id, {0, :account_id}}]
    end
  end

  describe "by_account_id/2" do
    test "adds account_id filter to existing query" do
      account_id = 456
      base_query = from(t in Transaction, where: t.workspace_id == 1)

      query = TransactionQuery.by_account_id(base_query, account_id)

      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {account_id, {0, :account_id}} in param_values
    end

    test "works with Transaction schema directly" do
      account_id = 789
      query = TransactionQuery.by_account_id(Transaction, account_id)

      assert query.from.source == {"transactions", Transaction}
      assert length(query.wheres) == 1
      assert hd(query.wheres).params == [{account_id, {0, :account_id}}]
    end

    test "preserves other query attributes" do
      base_query =
        from(t in Transaction,
          where: t.workspace_id == 1,
          order_by: t.date,
          limit: 5
        )

      query = TransactionQuery.by_account_id(base_query, 123)

      assert query.limit.expr == 5
      assert length(query.order_bys) == 1
      assert length(query.wheres) == 2
    end
  end

  describe "by_external_id/1" do
    test "creates a query filtered by external_id" do
      external_id = Ecto.UUID.generate()
      query = TransactionQuery.by_external_id(external_id)

      assert query.from.source == {"transactions", Transaction}

      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{external_id, {0, :external_id}}]
    end
  end

  describe "by_external_id/2" do
    test "adds external_id filter to existing query" do
      external_id = Ecto.UUID.generate()
      base_query = from(t in Transaction, where: t.workspace_id == 1)

      query = TransactionQuery.by_external_id(base_query, external_id)

      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {external_id, {0, :external_id}} in param_values
    end

    test "works with Transaction schema directly" do
      external_id = Ecto.UUID.generate()
      query = TransactionQuery.by_external_id(Transaction, external_id)

      assert query.from.source == {"transactions", Transaction}
      assert length(query.wheres) == 1
      assert hd(query.wheres).params == [{external_id, {0, :external_id}}]
    end

    test "preserves other query attributes" do
      base_query =
        from(t in Transaction,
          where: t.workspace_id == 1,
          order_by: t.date,
          limit: 5
        )

      external_id = Ecto.UUID.generate()
      query = TransactionQuery.by_external_id(base_query, external_id)

      assert query.limit.expr == 5
      assert length(query.order_bys) == 1
      assert length(query.wheres) == 2
    end
  end

  describe "by_linked_transaction_id/1" do
    test "creates a query filtered by linked_transaction_id" do
      linked_transaction_id = 123
      query = TransactionQuery.by_linked_transaction_id(linked_transaction_id)

      assert query.from.source == {"transactions", Transaction}

      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{linked_transaction_id, {0, :linked_transaction_id}}]
    end
  end

  describe "by_linked_transaction_id/2" do
    test "adds linked_transaction_id filter to existing query" do
      linked_transaction_id = 456
      base_query = from(t in Transaction, where: t.workspace_id == 1)

      query = TransactionQuery.by_linked_transaction_id(base_query, linked_transaction_id)

      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {linked_transaction_id, {0, :linked_transaction_id}} in param_values
    end

    test "works with Transaction schema directly" do
      linked_transaction_id = 789
      query = TransactionQuery.by_linked_transaction_id(Transaction, linked_transaction_id)

      assert query.from.source == {"transactions", Transaction}
      assert length(query.wheres) == 1
      assert hd(query.wheres).params == [{linked_transaction_id, {0, :linked_transaction_id}}]
    end

    test "preserves other query attributes" do
      base_query =
        from(t in Transaction,
          where: t.workspace_id == 1,
          order_by: t.date,
          limit: 5
        )

      query = TransactionQuery.by_linked_transaction_id(base_query, 123)

      assert query.limit.expr == 5
      assert length(query.order_bys) == 1
      assert length(query.wheres) == 2
    end
  end

  describe "by_date_range/2" do
    test "creates a query filtered by date range" do
      start_date = ~D[2025-01-01]
      end_date = ~D[2025-01-31]
      query = TransactionQuery.by_date_range(start_date, end_date)

      assert query.from.source == {"transactions", Transaction}

      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      param_values = where_clause.params
      assert {start_date, {0, :date}} in param_values
      assert {end_date, {0, :date}} in param_values
    end
  end

  describe "by_date_range/3" do
    test "adds date range filter to existing query" do
      start_date = ~D[2025-01-01]
      end_date = ~D[2025-01-31]
      base_query = from(t in Transaction, where: t.workspace_id == 1)

      query = TransactionQuery.by_date_range(base_query, start_date, end_date)

      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {start_date, {0, :date}} in param_values
      assert {end_date, {0, :date}} in param_values
    end

    test "works with Transaction schema directly" do
      start_date = ~D[2025-02-01]
      end_date = ~D[2025-02-28]
      query = TransactionQuery.by_date_range(Transaction, start_date, end_date)

      assert query.from.source == {"transactions", Transaction}
      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      param_values = where_clause.params
      assert {start_date, {0, :date}} in param_values
      assert {end_date, {0, :date}} in param_values
    end

    test "preserves other query attributes" do
      base_query =
        from(t in Transaction,
          where: t.workspace_id == 1,
          order_by: t.date,
          limit: 10
        )

      start_date = ~D[2025-03-01]
      end_date = ~D[2025-03-31]
      query = TransactionQuery.by_date_range(base_query, start_date, end_date)

      assert query.limit.expr == 10
      assert length(query.order_bys) == 1
      assert length(query.wheres) == 2
    end
  end

  describe "transfers_only/0" do
    test "creates a query filtering for non-null linked_transaction_id" do
      query = TransactionQuery.transfers_only()

      assert query.from.source == {"transactions", Transaction}
      assert length(query.wheres) == 1
    end
  end

  describe "transfers_only/1" do
    test "adds transfer filter to existing query" do
      base_query = from(t in Transaction, where: t.workspace_id == 1)

      query = TransactionQuery.transfers_only(base_query)

      assert length(query.wheres) == 2
    end

    test "works with Transaction schema directly" do
      query = TransactionQuery.transfers_only(Transaction)

      assert query.from.source == {"transactions", Transaction}
      assert length(query.wheres) == 1
    end

    test "preserves other query attributes" do
      base_query =
        from(t in Transaction,
          where: t.workspace_id == 1,
          order_by: t.date,
          limit: 5
        )

      query = TransactionQuery.transfers_only(base_query)

      assert query.limit.expr == 5
      assert length(query.order_bys) == 1
      assert length(query.wheres) == 2
    end
  end

  describe "order_by_date/0" do
    test "creates a query ordered by date and id in descending order" do
      query = TransactionQuery.order_by_date()

      assert query.from.source == {"transactions", Transaction}
      assert length(query.order_bys) == 1

      [order_by] = query.order_bys

      assert order_by.expr == [
               desc: {{:., [], [{:&, [], [0]}, :date]}, [], []},
               desc: {{:., [], [{:&, [], [0]}, :id]}, [], []}
             ]
    end
  end

  describe "order_by_date/1" do
    test "adds date and id ordering to existing query" do
      base_query = from(t in Transaction, where: t.workspace_id == 1)
      query = TransactionQuery.order_by_date(base_query)

      assert length(query.order_bys) == 1
      [order_by] = query.order_bys

      assert order_by.expr == [
               desc: {{:., [], [{:&, [], [0]}, :date]}, [], []},
               desc: {{:., [], [{:&, [], [0]}, :id]}, [], []}
             ]
    end

    test "works with Transaction schema directly" do
      query = TransactionQuery.order_by_date(Transaction)

      assert query.from.source == {"transactions", Transaction}
      assert length(query.order_bys) == 1
      [order_by] = query.order_bys

      assert order_by.expr == [
               desc: {{:., [], [{:&, [], [0]}, :date]}, [], []},
               desc: {{:., [], [{:&, [], [0]}, :id]}, [], []}
             ]
    end

    test "preserves other query attributes" do
      base_query =
        from(t in Transaction,
          where: t.workspace_id == 1,
          limit: 5
        )

      query = TransactionQuery.order_by_date(base_query)

      assert query.limit.expr == 5
      assert length(query.wheres) == 1
      assert length(query.order_bys) == 1
    end
  end

  describe "limit/1" do
    test "creates a query with limit" do
      count = 5
      query = TransactionQuery.limit(count)

      assert query.from.source == {"transactions", Transaction}
      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{5, :integer}]
    end
  end

  describe "limit/2" do
    test "adds limit to existing query" do
      base_query = from(t in Transaction, where: t.workspace_id == 1)
      count = 10
      query = TransactionQuery.limit(base_query, count)

      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{10, :integer}]
    end

    test "works with Transaction schema directly" do
      count = 3
      query = TransactionQuery.limit(Transaction, count)

      assert query.from.source == {"transactions", Transaction}
      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{3, :integer}]
    end

    test "preserves other query attributes" do
      base_query =
        from(t in Transaction,
          where: t.workspace_id == 1,
          order_by: t.date
        )

      count = 7
      query = TransactionQuery.limit(base_query, count)

      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{7, :integer}]
      assert length(query.wheres) == 1
      assert length(query.order_bys) == 1
    end
  end

  describe "preload_linked_transaction/0" do
    test "creates a query with linked_transaction preload" do
      query = TransactionQuery.preload_linked_transaction()

      assert query.from.source == {"transactions", Transaction}
      assert :linked_transaction in query.preloads
    end
  end

  describe "preload_linked_transaction/1" do
    test "adds preload to existing query" do
      base_query = from(t in Transaction, where: t.workspace_id == 1)

      query = TransactionQuery.preload_linked_transaction(base_query)

      assert :linked_transaction in query.preloads
      assert length(query.wheres) == 1
    end

    test "works with Transaction schema directly" do
      query = TransactionQuery.preload_linked_transaction(Transaction)

      assert query.from.source == {"transactions", Transaction}
      assert :linked_transaction in query.preloads
    end

    test "preserves other query attributes" do
      base_query =
        from(t in Transaction,
          where: t.workspace_id == 1,
          order_by: t.date,
          limit: 5
        )

      query = TransactionQuery.preload_linked_transaction(base_query)

      assert :linked_transaction in query.preloads
      assert query.limit.expr == 5
      assert length(query.order_bys) == 1
      assert length(query.wheres) == 1
    end
  end

  describe "query composition" do
    test "functions can be chained together" do
      workspace_id = 123
      account_id = 456
      external_id = Ecto.UUID.generate()
      start_date = ~D[2025-01-01]
      end_date = ~D[2025-01-31]

      query =
        workspace_id
        |> TransactionQuery.by_workspace_id()
        |> TransactionQuery.by_account_id(account_id)
        |> TransactionQuery.by_external_id(external_id)
        |> TransactionQuery.by_date_range(start_date, end_date)
        |> TransactionQuery.order_by_date()
        |> TransactionQuery.limit(10)

      assert query.from.source == {"transactions", Transaction}
      assert length(query.wheres) == 4
      assert length(query.order_bys) == 1
      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{10, :integer}]

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {workspace_id, {0, :workspace_id}} in param_values
      assert {account_id, {0, :account_id}} in param_values
      assert {external_id, {0, :external_id}} in param_values
      assert {start_date, {0, :date}} in param_values
      assert {end_date, {0, :date}} in param_values
    end

    test "functions work with arbitrary base queries" do
      base_query = from(t in "transactions", select: t.id)
      workspace_id = 456

      query =
        base_query
        |> TransactionQuery.by_workspace_id(workspace_id)
        |> TransactionQuery.order_by_date()

      assert query.from.source == {"transactions", nil}
      assert length(query.wheres) == 1
      assert length(query.order_bys) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{workspace_id, {0, :workspace_id}}]

      [order_by] = query.order_bys

      assert order_by.expr == [
               desc: {{:., [], [{:&, [], [0]}, :date]}, [], []},
               desc: {{:., [], [{:&, [], [0]}, :id]}, [], []}
             ]
    end

    test "dual-arity functions accept other schemas" do
      workspace_id = 789
      account_id = 321

      base_query = from(other in "other_table")

      query =
        base_query
        |> TransactionQuery.by_workspace_id(workspace_id)
        |> TransactionQuery.by_account_id(account_id)
        |> TransactionQuery.order_by_date()

      assert query.from.source == {"other_table", nil}
      assert length(query.wheres) == 2
      assert length(query.order_bys) == 1

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {workspace_id, {0, :workspace_id}} in param_values
      assert {account_id, {0, :account_id}} in param_values
    end

    test "transfer query functions chain together" do
      workspace_id = 123
      linked_transaction_id = 456

      query =
        workspace_id
        |> TransactionQuery.by_workspace_id()
        |> TransactionQuery.transfers_only()
        |> TransactionQuery.by_linked_transaction_id(linked_transaction_id)
        |> TransactionQuery.preload_linked_transaction()
        |> TransactionQuery.order_by_date()
        |> TransactionQuery.limit(10)

      assert query.from.source == {"transactions", Transaction}
      assert length(query.wheres) == 3
      assert :linked_transaction in query.preloads
      assert length(query.order_bys) == 1
      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{10, :integer}]

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {workspace_id, {0, :workspace_id}} in param_values
      assert {linked_transaction_id, {0, :linked_transaction_id}} in param_values
    end

    test "transfer queries work with existing functions" do
      workspace_id = 123
      account_id = 456

      query =
        workspace_id
        |> TransactionQuery.by_workspace_id()
        |> TransactionQuery.by_account_id(account_id)
        |> TransactionQuery.transfers_only()
        |> TransactionQuery.order_by_date()
        |> TransactionQuery.limit(5)

      assert query.from.source == {"transactions", Transaction}
      assert length(query.wheres) == 3
      assert length(query.order_bys) == 1
      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{5, :integer}]

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {workspace_id, {0, :workspace_id}} in param_values
      assert {account_id, {0, :account_id}} in param_values
    end
  end
end
