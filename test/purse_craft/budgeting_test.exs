defmodule PurseCraft.BudgetingTest do
  use PurseCraft.DataCase, async: true

  import PurseCraft.Factory

  alias PurseCraft.Budgeting
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Repo

  describe "list_books/0" do
    test "with existing Book record return a list of Book" do
      book = insert(:book)
      assert Budgeting.list_books() == [book]
    end

    test "with no existing Book record return empty list" do
      assert Budgeting.list_books() == []
    end
  end

  describe "fetch_book/1" do
    test "with existing book returns a tuple with the book of the given id" do
      book = insert(:book)

      assert {:ok, result} = Budgeting.fetch_book(book.id)
      assert book == result
    end

    test "with no existing book returns error tuple" do
      assert {:error, :not_found} = Budgeting.fetch_book(123)
    end
  end

  describe "get_book/1" do
    test "with existing book returns the book with the given id" do
      book = insert(:book)
      assert Budgeting.get_book(book.id) == book
    end

    test "with no existing book returns nil" do
      refute Budgeting.get_book(123)
    end
  end

  describe "create_book/1" do
    test "with valid data creates a book" do
      attrs = %{name: "some name"}

      assert {:ok, %Book{} = book} = Budgeting.create_book(attrs)
      assert book.name == "some name"
    end

    test "with invalid data returns error changeset" do
      attrs = %{name: nil}

      assert {:error, changeset} = Budgeting.create_book(attrs)

      errors = errors_on(changeset)

      assert errors
             |> Map.keys()
             |> length() == 1

      assert %{name: ["can't be blank"]} = errors
    end
  end

  describe "update_book/2" do
    test "with valid data updates the book" do
      book = insert(:book)
      attrs = %{name: "some updated name"}

      assert {:ok, %Book{} = book} = Budgeting.update_book(book, attrs)
      assert book.name == "some updated name"
    end

    test "with invalid data returns error changeset" do
      book = insert(:book)
      attrs = %{name: nil}

      assert {:error, changeset} = Budgeting.update_book(book, attrs)

      assert book == Repo.get(Book, book.id)

      errors = errors_on(changeset)

      assert errors
             |> Map.keys()
             |> length() == 1

      assert %{name: ["can't be blank"]} = errors
    end
  end

  describe "delete_book/1" do
    test "deletes the given book" do
      book = insert(:book)
      assert {:ok, %Book{}} = Budgeting.delete_book(book)
      refute Repo.get(Book, book.id)
    end
  end

  describe "change_book/1" do
    test "returns a book changeset" do
      book = insert(:book)
      assert %Ecto.Changeset{} = Budgeting.change_book(book)
    end
  end
end
