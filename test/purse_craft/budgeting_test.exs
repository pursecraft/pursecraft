defmodule PurseCraft.BudgetingTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Budgeting.Schemas.BookUser
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.Repo

  setup do
    user = IdentityFactory.insert(:user)
    book = BudgetingFactory.insert(:book)
    BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
    scope = IdentityFactory.build(:scope, user: user)

    %{
      user: user,
      scope: scope,
      book: book
    }
  end

  describe "fetch_book_by_external_id/3" do
    test "with associated book (authorized scope) returns book", %{scope: scope, book: book} do
      assert {:ok, fetched_book} = Budgeting.fetch_book_by_external_id(scope, book.external_id)
      assert fetched_book.id == book.id
      assert fetched_book.name == book.name
      assert fetched_book.external_id == book.external_id
    end

    test "with associated book and preload options returns preloaded book", %{scope: scope, book: book} do
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      assert {:ok, fetched_book} =
               Budgeting.fetch_book_by_external_id(scope, book.external_id, preload: [categories: :envelopes])

      assert [loaded_category] = fetched_book.categories
      assert loaded_category.id == category.id
      assert loaded_category.name == category.name

      assert [loaded_envelope] = loaded_category.envelopes
      assert loaded_envelope.id == envelope.id
      assert loaded_envelope.name == envelope.name
    end

    test "with non-existent book returns unauthorized error" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      non_existent_id = Ecto.UUID.generate()

      assert {:error, :unauthorized} = Budgeting.fetch_book_by_external_id(scope, non_existent_id)
    end

    test "with authorized scope but non-existent book returns not_found error" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      non_existent_id = Ecto.UUID.generate()

      Mimic.expect(PurseCraft.Budgeting.Policy, :authorize, fn :book_read, _scope, _object ->
        :ok
      end)

      assert {:error, :not_found} = Budgeting.fetch_book_by_external_id(scope, non_existent_id)
    end

    test "with no associated book (unauthorized scope) returns unauthorized error", %{book: book} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = Budgeting.fetch_book_by_external_id(scope, book.external_id)
    end
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
    test "with associated book, owner role (authorized scope) and valid data updates the book", %{
      scope: scope,
      book: book
    } do
      attrs = %{name: "some updated name"}

      assert {:ok, %Book{} = updated_book} = Budgeting.update_book(scope, book, attrs)
      assert updated_book.name == "some updated name"
    end

    test "with associated book, owner role (authorized scope) and invalid data returns error changeset", %{
      scope: scope,
      book: book
    } do
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
      scope = IdentityFactory.build(:scope, user: user)

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
      scope = IdentityFactory.build(:scope, user: user)

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

  describe "create_category/3" do
    test "with valid data creates a category", %{scope: scope, book: book} do
      attrs = %{name: "some category name"}

      assert {:ok, category} = Budgeting.create_category(scope, book, attrs)
      assert category.name == "some category name"
      assert category.book_id == book.id
    end

    test "with string keys in attrs creates a category correctly", %{scope: scope, book: book} do
      attrs = %{"name" => "string key category"}

      assert {:ok, category} = Budgeting.create_category(scope, book, attrs)
      assert category.name == "string key category"
      assert category.book_id == book.id
    end

    test "with mixed string and atom keys creates a category correctly", %{scope: scope, book: book} do
      attrs = %{"name" => "mixed keys category", priority: 1}

      assert {:ok, category} = Budgeting.create_category(scope, book, attrs)
      assert category.name == "mixed keys category"
    end

    test "with invalid data returns error changeset", %{scope: scope, book: book} do
      attrs = %{name: ""}

      assert {:error, changeset} = Budgeting.create_category(scope, book, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with owner role (authorized scope) creates a category", %{scope: scope, book: book} do
      # The default setup already has owner role
      attrs = %{name: "owner category"}

      assert {:ok, category} = Budgeting.create_category(scope, book, attrs)
      assert category.name == "owner category"
    end

    test "with editor role (authorized scope) creates a category", %{book: book} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "editor category"}

      assert {:ok, category} = Budgeting.create_category(scope, book, attrs)
      assert category.name == "editor category"
    end

    test "with commenter role (unauthorized scope) returns error", %{book: book} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "commenter category"}

      assert {:error, :unauthorized} = Budgeting.create_category(scope, book, attrs)
    end

    test "with no association to book (unauthorized scope) returns error", %{book: book} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "unauthorized category"}

      assert {:error, :unauthorized} = Budgeting.create_category(scope, book, attrs)
    end
  end

  describe "fetch_category_by_external_id/4" do
    setup %{book: book} do
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      %{category: category, envelope: envelope}
    end

    test "with associated category (authorized scope) returns category", %{
      scope: scope,
      book: book,
      category: category
    } do
      assert {:ok, fetched_category} = Budgeting.fetch_category_by_external_id(scope, book, category.external_id)
      assert fetched_category.id == category.id
      assert fetched_category.name == category.name
      assert fetched_category.external_id == category.external_id
      assert fetched_category.book_id == book.id
    end

    test "with associated category and preload options returns preloaded category", %{
      scope: scope,
      book: book,
      category: category,
      envelope: envelope
    } do
      assert {:ok, fetched_category} =
               Budgeting.fetch_category_by_external_id(scope, book, category.external_id, preload: [:envelopes])

      assert fetched_category.id == category.id
      assert fetched_category.name == category.name
      assert fetched_category.external_id == category.external_id

      assert [loaded_envelope] = fetched_category.envelopes
      assert loaded_envelope.id == envelope.id
      assert loaded_envelope.name == envelope.name
    end

    test "with non-existent category returns not_found error", %{scope: scope, book: book} do
      non_existent_id = Ecto.UUID.generate()

      assert {:error, :not_found} = Budgeting.fetch_category_by_external_id(scope, book, non_existent_id)
    end

    test "with category from a different book returns not_found error", %{scope: scope, book: book} do
      other_book = BudgetingFactory.insert(:book)
      BudgetingFactory.insert(:book_user, book_id: other_book.id, user_id: scope.user.id, role: :owner)

      other_category = BudgetingFactory.insert(:category, book_id: other_book.id)

      # Trying to fetch a category using its external_id but with the wrong book
      assert {:error, :not_found} = Budgeting.fetch_category_by_external_id(scope, book, other_category.external_id)
    end

    test "with editor role (authorized scope) returns category", %{
      book: book,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, fetched_category} = Budgeting.fetch_category_by_external_id(scope, book, category.external_id)
      assert fetched_category.id == category.id
    end

    test "with commenter role (authorized scope) returns category", %{
      book: book,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, fetched_category} = Budgeting.fetch_category_by_external_id(scope, book, category.external_id)
      assert fetched_category.id == category.id
    end

    test "with no association to book (unauthorized scope) returns error", %{
      book: book,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = Budgeting.fetch_category_by_external_id(scope, book, category.external_id)
    end
  end

  describe "update_category/5" do
    setup %{book: book} do
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      %{category: category, envelope: envelope}
    end

    test "with owner role (authorized scope) and valid data updates the category", %{
      scope: scope,
      book: book,
      category: category
    } do
      attrs = %{name: "updated category name"}

      assert {:ok, updated_category} = Budgeting.update_category(scope, book, category, attrs)
      assert updated_category.name == "updated category name"
      assert updated_category.book_id == book.id
    end

    test "with preload option returns category with associations", %{
      scope: scope,
      book: book,
      category: category,
      envelope: envelope
    } do
      attrs = %{name: "updated with preload"}

      assert {:ok, updated_category} = Budgeting.update_category(scope, book, category, attrs, preload: [:envelopes])
      assert updated_category.name == "updated with preload"
      assert [loaded_envelope] = updated_category.envelopes
      assert loaded_envelope.id == envelope.id
    end

    test "with editor role (authorized scope) and valid data updates the category", %{
      book: book,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "editor updated category"}

      assert {:ok, updated_category} = Budgeting.update_category(scope, book, category, attrs)
      assert updated_category.name == "editor updated category"
    end

    test "with commenter role (unauthorized scope) returns error", %{
      book: book,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "commenter category"}

      assert {:error, :unauthorized} = Budgeting.update_category(scope, book, category, attrs)
    end

    test "with no association to book (unauthorized scope) returns error", %{
      book: book,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "unauthorized category update"}

      assert {:error, :unauthorized} = Budgeting.update_category(scope, book, category, attrs)
    end

    test "with invalid data returns error changeset", %{
      scope: scope,
      book: book,
      category: category
    } do
      attrs = %{name: ""}

      assert {:error, changeset} = Budgeting.update_category(scope, book, category, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with string keys in attrs updates the category correctly", %{
      scope: scope,
      book: book,
      category: category
    } do
      attrs = %{"name" => "string key updated category"}

      assert {:ok, updated_category} = Budgeting.update_category(scope, book, category, attrs)
      assert updated_category.name == "string key updated category"
    end
  end

  describe "delete_category/3" do
    setup %{book: book} do
      category = BudgetingFactory.insert(:category, book_id: book.id)
      %{category: category}
    end

    test "with associated category, owner role (authorized scope) deletes the category", %{
      scope: scope,
      book: book,
      category: category
    } do
      assert {:ok, %Category{}} = Budgeting.delete_category(scope, book, category)
      assert {:error, :not_found} = Budgeting.fetch_category_by_external_id(scope, book, category.external_id)
    end

    test "with associated category, editor role (authorized scope) deletes the category", %{
      book: book,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, %Category{}} = Budgeting.delete_category(scope, book, category)
      assert {:error, :not_found} = Budgeting.fetch_category_by_external_id(scope, book, category.external_id)
    end

    test "with commenter role (unauthorized scope) returns error", %{
      book: book,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = Budgeting.delete_category(scope, book, category)
    end

    test "with no association to book (unauthorized scope) returns error", %{
      book: book,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = Budgeting.delete_category(scope, book, category)
    end
  end

  describe "change_category/2" do
    test "returns a category changeset", %{book: book} do
      category = BudgetingFactory.insert(:category, book_id: book.id)

      assert %Ecto.Changeset{} = Budgeting.change_category(category, %{})
    end
  end
end
