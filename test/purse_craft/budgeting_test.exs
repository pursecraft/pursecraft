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

  describe "list_categories/3" do
    setup %{book: book} do
      categories =
        for _index <- 1..3 do
          BudgetingFactory.insert(:category, book_id: book.id)
        end

      other_book = BudgetingFactory.insert(:book)
      other_category = BudgetingFactory.insert(:category, book_id: other_book.id)

      %{categories: categories, other_book: other_book, other_category: other_category}
    end

    test "with associated book (authorized scope) returns all book categories", %{
      scope: scope,
      book: book,
      categories: categories
    } do
      result = Budgeting.list_categories(scope, book)

      sorted_result = Enum.sort_by(result, & &1.id)
      sorted_categories = Enum.sort_by(categories, & &1.id)

      assert length(sorted_result) == length(sorted_categories)

      sorted_result
      |> Enum.zip(sorted_categories)
      |> Enum.each(fn {result_cat, expected_cat} ->
        assert result_cat.id == expected_cat.id
        assert result_cat.name == expected_cat.name
        assert result_cat.external_id == expected_cat.external_id
        assert result_cat.book_id == book.id
      end)
    end

    test "with associated book and preload option returns categories with associations", %{
      scope: scope,
      book: book,
      categories: categories
    } do
      category = List.first(categories)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      result = Budgeting.list_categories(scope, book, preload: [:envelopes])

      category_with_envelope = Enum.find(result, fn cat -> cat.id == category.id end)
      assert [loaded_envelope] = category_with_envelope.envelopes
      assert loaded_envelope.id == envelope.id
      assert loaded_envelope.name == envelope.name

      other_categories = Enum.filter(result, fn cat -> cat.id != category.id end)

      Enum.each(other_categories, fn cat ->
        assert cat.envelopes == []
      end)
    end

    test "with editor role (authorized scope) returns categories", %{
      book: book,
      categories: categories
    } do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      result = Budgeting.list_categories(scope, book)
      assert length(result) == length(categories)
    end

    test "with commenter role (authorized scope) returns categories", %{
      book: book,
      categories: categories
    } do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      result = Budgeting.list_categories(scope, book)
      assert length(result) == length(categories)
    end

    test "with no association to book (unauthorized scope) returns error", %{
      book: book
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = Budgeting.list_categories(scope, book)
    end

    test "returns only categories for the specified book", %{
      scope: scope,
      book: book,
      categories: categories,
      other_book: other_book,
      other_category: other_category
    } do
      BudgetingFactory.insert(:book_user, book_id: other_book.id, user_id: scope.user.id, role: :owner)

      book_categories = Budgeting.list_categories(scope, book)
      assert length(book_categories) == length(categories)
      assert Enum.all?(book_categories, fn cat -> cat.book_id == book.id end)

      other_book_categories = Budgeting.list_categories(scope, other_book)
      assert length(other_book_categories) == 1
      assert hd(other_book_categories).id == other_category.id
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

  describe "change_category/2" do
    test "returns a category changeset", %{book: book} do
      category = BudgetingFactory.insert(:category, book_id: book.id)

      assert %Ecto.Changeset{} = Budgeting.change_category(category, %{})
    end
  end

  describe "create_envelope/4" do
    setup %{book: book} do
      category = BudgetingFactory.insert(:category, book_id: book.id)
      %{category: category}
    end

    test "with valid data creates an envelope", %{scope: scope, book: book, category: category} do
      attrs = %{name: "some envelope name"}

      assert {:ok, envelope} = Budgeting.create_envelope(scope, book, category, attrs)
      assert envelope.name == "some envelope name"
      assert envelope.category_id == category.id
    end

    test "with string keys in attrs creates an envelope correctly", %{scope: scope, book: book, category: category} do
      attrs = %{"name" => "string key envelope"}

      assert {:ok, envelope} = Budgeting.create_envelope(scope, book, category, attrs)
      assert envelope.name == "string key envelope"
      assert envelope.category_id == category.id
    end

    test "with invalid data returns error changeset", %{scope: scope, book: book, category: category} do
      attrs = %{name: ""}

      assert {:error, changeset} = Budgeting.create_envelope(scope, book, category, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with owner role (authorized scope) creates an envelope", %{scope: scope, book: book, category: category} do
      attrs = %{name: "owner envelope"}

      assert {:ok, envelope} = Budgeting.create_envelope(scope, book, category, attrs)
      assert envelope.name == "owner envelope"
    end

    test "with editor role (authorized scope) creates an envelope", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "editor envelope"}

      assert {:ok, envelope} = Budgeting.create_envelope(scope, book, category, attrs)
      assert envelope.name == "editor envelope"
    end

    test "with commenter role (unauthorized scope) returns error", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "commenter envelope"}

      assert {:error, :unauthorized} = Budgeting.create_envelope(scope, book, category, attrs)
    end

    test "with no association to book (unauthorized scope) returns error", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "unauthorized envelope"}

      assert {:error, :unauthorized} = Budgeting.create_envelope(scope, book, category, attrs)
    end
  end

  describe "fetch_envelope_by_external_id/3" do
    setup %{book: book} do
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      %{category: category, envelope: envelope}
    end

    test "with associated envelope (authorized scope) returns envelope", %{
      scope: scope,
      book: book,
      envelope: envelope
    } do
      assert {:ok, fetched_envelope} = Budgeting.fetch_envelope_by_external_id(scope, book, envelope.external_id)
      assert fetched_envelope.id == envelope.id
      assert fetched_envelope.name == envelope.name
      assert fetched_envelope.external_id == envelope.external_id
      assert fetched_envelope.category_id == envelope.category_id
    end

    test "with non-existent envelope returns not_found error", %{scope: scope, book: book} do
      non_existent_id = Ecto.UUID.generate()

      assert {:error, :not_found} = Budgeting.fetch_envelope_by_external_id(scope, book, non_existent_id)
    end

    test "with envelope from a different book returns not_found error", %{scope: scope, book: book} do
      other_book = BudgetingFactory.insert(:book)
      BudgetingFactory.insert(:book_user, book_id: other_book.id, user_id: scope.user.id, role: :owner)

      other_category = BudgetingFactory.insert(:category, book_id: other_book.id)
      other_envelope = BudgetingFactory.insert(:envelope, category_id: other_category.id)

      assert {:error, :not_found} = Budgeting.fetch_envelope_by_external_id(scope, book, other_envelope.external_id)
    end

    test "with editor role (authorized scope) returns envelope", %{
      book: book,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, fetched_envelope} = Budgeting.fetch_envelope_by_external_id(scope, book, envelope.external_id)
      assert fetched_envelope.id == envelope.id
    end

    test "with commenter role (authorized scope) returns envelope", %{
      book: book,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, fetched_envelope} = Budgeting.fetch_envelope_by_external_id(scope, book, envelope.external_id)
      assert fetched_envelope.id == envelope.id
    end

    test "with no association to book (unauthorized scope) returns error", %{
      book: book,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = Budgeting.fetch_envelope_by_external_id(scope, book, envelope.external_id)
    end
  end

  describe "update_envelope/4" do
    setup %{book: book} do
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      %{category: category, envelope: envelope}
    end

    test "with owner role (authorized scope) and valid data updates the envelope", %{
      scope: scope,
      book: book,
      envelope: envelope
    } do
      attrs = %{name: "updated envelope name"}

      assert {:ok, updated_envelope} = Budgeting.update_envelope(scope, book, envelope, attrs)
      assert updated_envelope.name == "updated envelope name"
      assert updated_envelope.category_id == envelope.category_id
    end

    test "with editor role (authorized scope) and valid data updates the envelope", %{
      book: book,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "editor updated envelope"}

      assert {:ok, updated_envelope} = Budgeting.update_envelope(scope, book, envelope, attrs)
      assert updated_envelope.name == "editor updated envelope"
    end

    test "with commenter role (unauthorized scope) returns error", %{
      book: book,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "commenter envelope"}

      assert {:error, :unauthorized} = Budgeting.update_envelope(scope, book, envelope, attrs)
    end

    test "with no association to book (unauthorized scope) returns error", %{
      book: book,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "unauthorized envelope update"}

      assert {:error, :unauthorized} = Budgeting.update_envelope(scope, book, envelope, attrs)
    end

    test "with invalid data returns error changeset", %{
      scope: scope,
      book: book,
      envelope: envelope
    } do
      attrs = %{name: ""}

      assert {:error, changeset} = Budgeting.update_envelope(scope, book, envelope, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with string keys in attrs updates the envelope correctly", %{
      scope: scope,
      book: book,
      envelope: envelope
    } do
      attrs = %{"name" => "string key updated envelope"}

      assert {:ok, updated_envelope} = Budgeting.update_envelope(scope, book, envelope, attrs)
      assert updated_envelope.name == "string key updated envelope"
    end
  end
end
