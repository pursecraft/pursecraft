defmodule PurseCraft.Accounting.Queries.AccountQueryTest do
  use PurseCraft.DataCase, async: true

  import Ecto.Query

  alias PurseCraft.Accounting.Queries.AccountQuery
  alias PurseCraft.Accounting.Schemas.Account

  describe "by_book_id/1" do
    test "creates a query filtered by book_id" do
      book_id = 123
      query = AccountQuery.by_book_id(book_id)

      assert query.from.source == {"accounts", Account}

      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{book_id, {0, :book_id}}]
    end
  end

  describe "by_book_id/2" do
    test "adds book_id filter to existing query" do
      book_id = 456
      base_query = from(a in Account, where: a.name == "Test Account")

      query = AccountQuery.by_book_id(base_query, book_id)

      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {book_id, {0, :book_id}} in param_values
    end

    test "works with Account schema directly" do
      book_id = 789
      query = AccountQuery.by_book_id(Account, book_id)

      assert query.from.source == {"accounts", Account}
      assert length(query.wheres) == 1
      assert hd(query.wheres).params == [{book_id, {0, :book_id}}]
    end
  end

  describe "order_by_position/0" do
    test "creates a query ordered by position in ascending order" do
      query = AccountQuery.order_by_position()

      assert query.from.source == {"accounts", Account}
      assert length(query.order_bys) == 1

      [order_by] = query.order_bys
      assert order_by.expr == [asc: {{:., [], [{:&, [], [0]}, :position]}, [], []}]
    end
  end

  describe "order_by_position/1" do
    test "adds position ordering to existing query" do
      base_query = from(a in Account, where: a.book_id == 1)
      query = AccountQuery.order_by_position(base_query)

      assert length(query.order_bys) == 1
      [order_by] = query.order_bys
      assert order_by.expr == [asc: {{:., [], [{:&, [], [0]}, :position]}, [], []}]
    end
  end

  describe "limit/1" do
    test "creates a query with limit" do
      count = 5
      query = AccountQuery.limit(count)

      assert query.from.source == {"accounts", Account}
      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{5, :integer}]
    end
  end

  describe "limit/2" do
    test "adds limit to existing query" do
      base_query = from(a in Account, where: a.book_id == 1)
      count = 10
      query = AccountQuery.limit(base_query, count)

      assert query.limit.expr == {:^, [], [0]}
      assert query.limit.params == [{10, :integer}]
    end
  end

  describe "select_position/0" do
    test "creates a query selecting only position field" do
      query = AccountQuery.select_position()

      assert query.from.source == {"accounts", Account}
      assert query.select.expr == {{:., [], [{:&, [], [0]}, :position]}, [], []}
    end
  end

  describe "select_position/1" do
    test "adds position selection to existing query" do
      base_query = from(a in Account, where: a.book_id == 1)
      query = AccountQuery.select_position(base_query)

      assert query.select.expr == {{:., [], [{:&, [], [0]}, :position]}, [], []}
    end
  end

  describe "by_external_id/1" do
    test "creates a query filtered by external_id" do
      external_id = Ecto.UUID.generate()
      query = AccountQuery.by_external_id(external_id)

      assert query.from.source == {"accounts", Account}
      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.params == [{external_id, {0, :external_id}}]
    end
  end

  describe "by_external_id/2" do
    test "adds external_id filter to existing query" do
      external_id = Ecto.UUID.generate()
      base_query = from(a in Account, where: a.book_id == 1)

      query = AccountQuery.by_external_id(base_query, external_id)

      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {external_id, {0, :external_id}} in param_values
    end
  end

  describe "active/0" do
    test "creates a query filtering for active accounts" do
      query = AccountQuery.active()

      assert query.from.source == {"accounts", Account}
      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      assert where_clause.expr == {:is_nil, [], [{{:., [], [{:&, [], [0]}, :closed_at]}, [], []}]}
    end
  end

  describe "active/1" do
    test "adds active filter to existing query" do
      base_query = from(a in Account, where: a.book_id == 1)
      query = AccountQuery.active(base_query)

      assert length(query.wheres) == 2

      active_where =
        Enum.find(query.wheres, fn w ->
          w.expr == {:is_nil, [], [{{:., [], [{:&, [], [0]}, :closed_at]}, [], []}]}
        end)

      assert active_where != nil
    end
  end

  describe "by_external_ids/1" do
    test "creates a query filtering by external IDs" do
      external_ids = [Ecto.UUID.generate(), Ecto.UUID.generate()]
      query = AccountQuery.by_external_ids(external_ids)

      assert query.from.source == {"accounts", Account}
      assert length(query.wheres) == 1

      [where_clause] = query.wheres
      param_values = where_clause.params
      assert {external_ids, {:in, {0, :external_id}}} in param_values
    end
  end

  describe "by_external_ids/2" do
    test "adds external IDs filter to existing query" do
      external_ids = [Ecto.UUID.generate(), Ecto.UUID.generate()]
      base_query = from(a in Account, where: a.book_id == 1)

      query = AccountQuery.by_external_ids(base_query, external_ids)

      assert length(query.wheres) == 2

      param_values = Enum.flat_map(query.wheres, & &1.params)
      assert {external_ids, {:in, {0, :external_id}}} in param_values
    end
  end
end
