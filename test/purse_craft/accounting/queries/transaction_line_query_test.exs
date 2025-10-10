defmodule PurseCraft.Accounting.Queries.TransactionLineQueryTest do
  use PurseCraft.DataCase, async: true

  import Ecto.Query

  alias PurseCraft.Accounting.Queries.TransactionLineQuery
  alias PurseCraft.Accounting.Schemas.TransactionLine

  describe "by_transaction_id/1" do
    test "creates a query filtered by transaction_id" do
      transaction_id = 123
      query = TransactionLineQuery.by_transaction_id(transaction_id)

      assert query.from.source == {"transaction_lines", TransactionLine}

      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{transaction_id, {0, :transaction_id}}]
    end
  end

  describe "by_transaction_id/2" do
    test "adds transaction_id filter to existing query" do
      transaction_id = 456
      base_query = from(tl in TransactionLine, where: tl.amount > 0)

      query = TransactionLineQuery.by_transaction_id(base_query, transaction_id)

      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {transaction_id, {0, :transaction_id}} in param_values
    end

    test "works with TransactionLine schema directly" do
      transaction_id = 789
      query = TransactionLineQuery.by_transaction_id(TransactionLine, transaction_id)

      assert query.from.source == {"transaction_lines", TransactionLine}
      assert length(query.wheres) == 1
      assert hd(query.wheres).params == [{transaction_id, {0, :transaction_id}}]
    end

    test "preserves other query attributes" do
      base_query =
        from(tl in TransactionLine,
          where: tl.amount > 0,
          order_by: tl.inserted_at,
          limit: 10
        )

      query = TransactionLineQuery.by_transaction_id(base_query, 123)

      assert query.limit.expr == 10
      assert length(query.order_bys) == 1
      assert length(query.wheres) == 2
    end
  end

  describe "by_envelope_id/1" do
    test "creates a query filtered by envelope_id" do
      envelope_id = 123
      query = TransactionLineQuery.by_envelope_id(envelope_id)

      assert query.from.source == {"transaction_lines", TransactionLine}

      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{envelope_id, {0, :envelope_id}}]
    end
  end

  describe "by_envelope_id/2" do
    test "adds envelope_id filter to existing query" do
      envelope_id = 456
      base_query = from(tl in TransactionLine, where: tl.amount > 0)

      query = TransactionLineQuery.by_envelope_id(base_query, envelope_id)

      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {envelope_id, {0, :envelope_id}} in param_values
    end

    test "works with TransactionLine schema directly" do
      envelope_id = 789
      query = TransactionLineQuery.by_envelope_id(TransactionLine, envelope_id)

      assert query.from.source == {"transaction_lines", TransactionLine}
      assert length(query.wheres) == 1
      assert hd(query.wheres).params == [{envelope_id, {0, :envelope_id}}]
    end

    test "preserves other query attributes" do
      base_query =
        from(tl in TransactionLine,
          where: tl.amount > 0,
          order_by: tl.inserted_at,
          limit: 5
        )

      query = TransactionLineQuery.by_envelope_id(base_query, 123)

      assert query.limit.expr == 5
      assert length(query.order_bys) == 1
      assert length(query.wheres) == 2
    end
  end

  describe "ready_to_assign_only/0" do
    test "creates a query filtered for nil envelope_id" do
      query = TransactionLineQuery.ready_to_assign_only()

      assert query.from.source == {"transaction_lines", TransactionLine}

      assert length(query.wheres) == 1

      [where_clause] = query.wheres

      assert where_clause.expr ==
               {:is_nil, [], [{{:., [], [{:&, [], [0]}, :envelope_id]}, [], []}]}
    end
  end

  describe "ready_to_assign_only/1" do
    test "adds nil envelope_id filter to existing query" do
      base_query = from(tl in TransactionLine, where: tl.amount > 0)

      query = TransactionLineQuery.ready_to_assign_only(base_query)

      assert length(query.wheres) == 2

      nil_where =
        Enum.find(query.wheres, fn where ->
          match?(
            {:is_nil, [], [{{:., [], [{:&, [], [0]}, :envelope_id]}, _metadata, []}]},
            where.expr
          )
        end)

      assert nil_where != nil
    end

    test "works with TransactionLine schema directly" do
      query = TransactionLineQuery.ready_to_assign_only(TransactionLine)

      assert query.from.source == {"transaction_lines", TransactionLine}
      assert length(query.wheres) == 1

      [where_clause] = query.wheres

      assert where_clause.expr ==
               {:is_nil, [], [{{:., [], [{:&, [], [0]}, :envelope_id]}, [], []}]}
    end

    test "preserves other query attributes" do
      base_query =
        from(tl in TransactionLine,
          where: tl.amount > 0,
          order_by: tl.inserted_at,
          limit: 10
        )

      query = TransactionLineQuery.ready_to_assign_only(base_query)

      assert query.limit.expr == 10
      assert length(query.order_bys) == 1
      assert length(query.wheres) == 2
    end
  end

  describe "query composition" do
    test "functions can be chained together" do
      transaction_id = 123
      envelope_id = 456

      query =
        transaction_id
        |> TransactionLineQuery.by_transaction_id()
        |> TransactionLineQuery.by_envelope_id(envelope_id)

      assert query.from.source == {"transaction_lines", TransactionLine}
      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {transaction_id, {0, :transaction_id}} in param_values
      assert {envelope_id, {0, :envelope_id}} in param_values
    end

    test "ready_to_assign_only can be composed with other filters" do
      transaction_id = 789

      query =
        transaction_id
        |> TransactionLineQuery.by_transaction_id()
        |> TransactionLineQuery.ready_to_assign_only()

      assert query.from.source == {"transaction_lines", TransactionLine}
      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {transaction_id, {0, :transaction_id}} in param_values

      nil_where =
        Enum.find(query.wheres, fn where ->
          match?(
            {:is_nil, [], [{{:., [], [{:&, [], [0]}, :envelope_id]}, _metadata, []}]},
            where.expr
          )
        end)

      assert nil_where != nil
    end

    test "functions work with arbitrary base queries" do
      base_query = from(tl in "transaction_lines", select: tl.id)
      transaction_id = 456

      query =
        base_query
        |> TransactionLineQuery.by_transaction_id(transaction_id)
        |> TransactionLineQuery.ready_to_assign_only()

      assert query.from.source == {"transaction_lines", nil}
      assert length(query.wheres) == 2

      [where_clause] =
        Enum.filter(query.wheres, &match?([{_value, {0, :transaction_id}}], &1.params))

      assert where_clause.params == [{transaction_id, {0, :transaction_id}}]
    end

    test "dual-arity functions accept other schemas" do
      transaction_id = 789
      envelope_id = 321

      base_query = from(other in "other_table")

      query =
        base_query
        |> TransactionLineQuery.by_transaction_id(transaction_id)
        |> TransactionLineQuery.by_envelope_id(envelope_id)

      assert query.from.source == {"other_table", nil}
      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {transaction_id, {0, :transaction_id}} in param_values
      assert {envelope_id, {0, :envelope_id}} in param_values
    end
  end
end
