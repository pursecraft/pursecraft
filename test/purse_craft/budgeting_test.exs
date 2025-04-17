defmodule PurseCraft.BudgetingTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Budgeting.Schemas.BookUser
  alias PurseCraft.IdentityFactory
  alias PurseCraft.Repo

  setup do
    user = IdentityFactory.insert(:user)
    book = BudgetingFactory.insert(:book)
    BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
    scope = IdentityFactory.build(:scope, user: user, book: book)

    %{
      user: user,
      scope: scope,
      book: book
    }
  end

  describe "list_books/1" do
    test "with associated books returns all scoped books", %{scope: scope, book: book} do
      other_user = IdentityFactory.insert(:user)
      other_scope = IdentityFactory.build(:scope, user: other_user)
      other_book = BudgetingFactory.insert(:book)

      BudgetingFactory.insert(:book_user, book_id: other_book.id, user_id: other_user.id)

      assert Budgeting.list_books(scope) == [book]
      assert Budgeting.list_books(other_scope) == [other_book]
    end

    test "with no associated books returns empty list" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert Budgeting.list_books(scope) == []
    end
  end

  describe "get_book_by_external_id!/2" do
    test "with associated book (authorized scope) returns book", %{scope: scope, book: book} do
      assert Budgeting.get_book_by_external_id!(scope, book.external_id) == book
    end

    test "with no associated books (unauthorized scope) raises `LetMe.UnauthorizedError`" do
      assert_raise LetMe.UnauthorizedError, fn ->
        user = IdentityFactory.insert(:user)
        scope = IdentityFactory.build(:scope, user: user)
        book = BudgetingFactory.insert(:book)

        Budgeting.get_book_by_external_id!(scope, book.external_id)
      end
    end
  end

  describe "create_book/2" do
    test "with valid data creates a book" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      attrs = %{name: "some name"}

      assert {:ok, %Book{} = book} = Budgeting.create_book(scope, attrs)
      assert book.name == "some name"

      book_user = Repo.get_by(BookUser, book_id: book.id)

      assert book_user.user_id == scope.user.id
      assert book_user.role == :owner
    end

    test "with no name returns error changeset" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      attrs = %{}

      assert {:error, changeset} = Budgeting.create_book(scope, attrs)

      errors = errors_on(changeset)

      assert errors
             |> Map.keys()
             |> length() == 1

      assert %{name: ["can't be blank"]} = errors
    end
  end

  describe "update_book/3" do
    test "with associated book, owner role (authorized scope) and valid data updates the book", %{scope: scope, book: book} do
      attrs = %{name: "some updated name"}

      assert {:ok, %Book{} = updated_book} = Budgeting.update_book(scope, book, attrs)
      assert updated_book.name == "some updated name"
    end

    test "with associated book, owner role (authorized scope) and invalid data returns error changeset", %{scope: scope, book: book} do
      attrs = %{name: ""}

      assert {:error, changeset} = Budgeting.update_book(scope, book, attrs)

      errors = errors_on(changeset)

      assert errors
             |> Map.keys()
             |> length() == 1

      assert %{name: ["can't be blank"]} = errors
    end

    test "with associated book, non-owner role (unauthorized scope) and valid data updates the book", %{book: book} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user, book: book)

      attrs = %{name: "some updated name"}

      assert {:error, :unauthorized} = Budgeting.update_book(scope, book, attrs)
    end

    test "with no associated book (unauthorized scope) returns error tuple", %{book: book} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "some updated name"}

      assert {:error, :unauthorized} = Budgeting.update_book(scope, book, attrs)
    end
  end

  describe "delete_book/2" do
    test "with associate book, owner role (authorized scope) deletes the book", %{scope: scope, book: book} do
      assert {:ok, %Book{}} = Budgeting.delete_book(scope, book)

      assert_raise LetMe.UnauthorizedError, fn ->
        Budgeting.get_book_by_external_id!(scope, book.external_id)
      end
    end

    test "with associated book, non-owner role (unauthorized scope) and valid data updates the book", %{book: book} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user, book: book)

      assert {:error, :unauthorized} = Budgeting.delete_book(scope, book)
    end

    test "with no associated book (unauthorized scope) returns error tuple", %{book: book} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = Budgeting.delete_book(scope, book)
    end
  end

  describe "change_book/2" do
    test "returns a book changeset" do
      book = BudgetingFactory.insert(:book)

      assert %Ecto.Changeset{} = Budgeting.change_book(book, %{})
    end
  end
end
