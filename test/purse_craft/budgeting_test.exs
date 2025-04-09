defmodule PurseCraft.BudgetingTest do
  use PurseCraft.DataCase

  alias PurseCraft.Budgeting

  describe "books" do
    alias PurseCraft.Budgeting.Book

    import PurseCraft.TestHelpers.IdentityHelper, only: [user_scope_fixture: 0]
    import PurseCraft.BudgetingFixtures

    @invalid_attrs %{name: nil}

    test "list_books/1 returns all scoped books" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      book = book_fixture(scope)
      other_book = book_fixture(other_scope)
      assert Budgeting.list_books(scope) == [book]
      assert Budgeting.list_books(other_scope) == [other_book]
    end

    test "get_book!/2 returns the book with given id" do
      scope = user_scope_fixture()
      book = book_fixture(scope)
      other_scope = user_scope_fixture()
      assert Budgeting.get_book!(scope, book.id) == book
      assert_raise Ecto.NoResultsError, fn -> Budgeting.get_book!(other_scope, book.id) end
    end

    test "create_book/2 with valid data creates a book" do
      valid_attrs = %{name: "some name"}
      scope = user_scope_fixture()

      assert {:ok, %Book{} = book} = Budgeting.create_book(scope, valid_attrs)
      assert book.name == "some name"
      assert book.user_id == scope.user.id
    end

    test "create_book/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Budgeting.create_book(scope, @invalid_attrs)
    end

    test "update_book/3 with valid data updates the book" do
      scope = user_scope_fixture()
      book = book_fixture(scope)
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Book{} = book} = Budgeting.update_book(scope, book, update_attrs)
      assert book.name == "some updated name"
    end

    test "update_book/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      book = book_fixture(scope)

      assert_raise MatchError, fn ->
        Budgeting.update_book(other_scope, book, %{})
      end
    end

    test "update_book/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      book = book_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Budgeting.update_book(scope, book, @invalid_attrs)
      assert book == Budgeting.get_book!(scope, book.id)
    end

    test "delete_book/2 deletes the book" do
      scope = user_scope_fixture()
      book = book_fixture(scope)
      assert {:ok, %Book{}} = Budgeting.delete_book(scope, book)
      assert_raise Ecto.NoResultsError, fn -> Budgeting.get_book!(scope, book.id) end
    end

    test "delete_book/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      book = book_fixture(scope)
      assert_raise MatchError, fn -> Budgeting.delete_book(other_scope, book) end
    end

    test "change_book/2 returns a book changeset" do
      scope = user_scope_fixture()
      book = book_fixture(scope)
      assert %Ecto.Changeset{} = Budgeting.change_book(scope, book)
    end
  end
end
