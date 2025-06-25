defmodule PurseCraft.Accounting.Queries.AccountQueryTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Accounting.Queries.AccountQuery
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.CoreFactory

  describe "by_book_id/1" do
    test "returns query for finding accounts by book ID" do
      book = CoreFactory.insert(:book)

      query = AccountQuery.by_book_id(book.id)

      assert %Ecto.Query{} = query
      assert inspect(query) =~ "where: a0.book_id == ^#{book.id}"
    end
  end

  describe "by_book_id/2" do
    test "adds book_id filter to existing query" do
      book = CoreFactory.insert(:book)

      query = AccountQuery.by_book_id(Account, book.id)

      assert %Ecto.Query{} = query
      assert inspect(query) =~ "where: a0.book_id == ^#{book.id}"
    end

    test "preserves existing query conditions" do
      book = CoreFactory.insert(:book)

      query =
        Account
        |> AccountQuery.order_by_position()
        |> AccountQuery.by_book_id(book.id)

      assert %Ecto.Query{} = query
      assert inspect(query) =~ "order_by: [asc: a0.position]"
      assert inspect(query) =~ "where: a0.book_id == ^#{book.id}"
    end
  end

  describe "order_by_position/0" do
    test "returns query ordered by position ascending" do
      query = AccountQuery.order_by_position()

      assert %Ecto.Query{} = query
      assert inspect(query) =~ "order_by: [asc: a0.position]"
    end
  end

  describe "order_by_position/1" do
    test "adds position ordering to existing query" do
      book = CoreFactory.insert(:book)

      query =
        Account
        |> AccountQuery.by_book_id(book.id)
        |> AccountQuery.order_by_position()

      assert %Ecto.Query{} = query
      assert inspect(query) =~ "order_by: [asc: a0.position]"
      assert inspect(query) =~ "where: a0.book_id == ^#{book.id}"
    end
  end

  describe "limit/1" do
    test "returns query with limit" do
      query = AccountQuery.limit(5)

      assert %Ecto.Query{} = query
      assert inspect(query) =~ "limit: ^5"
    end
  end

  describe "limit/2" do
    test "adds limit to existing query" do
      book = CoreFactory.insert(:book)

      query =
        Account
        |> AccountQuery.by_book_id(book.id)
        |> AccountQuery.limit(3)

      assert %Ecto.Query{} = query
      assert inspect(query) =~ "limit: ^3"
      assert inspect(query) =~ "where: a0.book_id == ^#{book.id}"
    end

    test "overwrites existing limit" do
      query =
        Account
        |> AccountQuery.limit(5)
        |> AccountQuery.limit(2)

      assert %Ecto.Query{} = query
      assert inspect(query) =~ "limit: ^2"
      refute inspect(query) =~ "limit: ^5"
    end
  end

  describe "select_position/0" do
    test "returns query selecting only position field" do
      query = AccountQuery.select_position()

      assert %Ecto.Query{} = query
      assert inspect(query) =~ "select: a0.position"
    end
  end

  describe "select_position/1" do
    test "adds position select to existing query" do
      book = CoreFactory.insert(:book)

      query =
        Account
        |> AccountQuery.by_book_id(book.id)
        |> AccountQuery.select_position()

      assert %Ecto.Query{} = query
      assert inspect(query) =~ "select: a0.position"
      assert inspect(query) =~ "where: a0.book_id == ^#{book.id}"
    end
  end
end
