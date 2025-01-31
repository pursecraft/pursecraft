defmodule PurseCraft.BudgetingTest do
  use PurseCraft.DataCase

  import PurseCraft.Factory

  alias PurseCraft.Budgeting
  alias PurseCraft.Budgeting.Schemas.Book

  describe "books" do
    @invalid_attrs %{name: nil}

    test "list_books/0 returns all books" do
      book = insert(:book)
      assert Budgeting.list_books() == [book]
    end

    test "get_book!/1 returns the book with given id" do
      book = insert(:book)
      assert Budgeting.get_book!(book.id) == book
    end

    test "create_book/1 with valid data creates a book" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Book{} = book} = Budgeting.create_book(valid_attrs)
      assert book.name == "some name"
    end

    test "create_book/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Budgeting.create_book(@invalid_attrs)
    end

    test "update_book/2 with valid data updates the book" do
      book = insert(:book)
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Book{} = book} = Budgeting.update_book(book, update_attrs)
      assert book.name == "some updated name"
    end

    test "update_book/2 with invalid data returns error changeset" do
      book = insert(:book)
      assert {:error, %Ecto.Changeset{}} = Budgeting.update_book(book, @invalid_attrs)
      assert book == Budgeting.get_book!(book.id)
    end

    test "delete_book/1 deletes the book" do
      book = insert(:book)
      assert {:ok, %Book{}} = Budgeting.delete_book(book)
      assert_raise Ecto.NoResultsError, fn -> Budgeting.get_book!(book.id) end
    end

    test "change_book/1 returns a book changeset" do
      book = insert(:book)
      assert %Ecto.Changeset{} = Budgeting.change_book(book)
    end
  end
end
