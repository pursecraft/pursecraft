defmodule PurseCraft.BudgetingTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Budgeting.Schemas.BookUser
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Budgeting.Schemas.Envelope
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
    test "with valid data creates a category at position 0 and shifts others", %{scope: scope, book: book} do
      # First create some categories with known positions
      category1 = BudgetingFactory.insert(:category, book_id: book.id, position: 0)
      category2 = BudgetingFactory.insert(:category, book_id: book.id, position: 1)

      attrs = %{name: "new category"}

      assert {:ok, new_category} = Budgeting.create_category(scope, book, attrs)
      assert new_category.name == "new category"
      assert new_category.book_id == book.id
      assert new_category.position == 0

      # Verify that existing categories were shifted down
      reloaded_category1 = Repo.reload(category1)
      reloaded_category2 = Repo.reload(category2)

      assert reloaded_category1.position == 1
      assert reloaded_category2.position == 2
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
        for index <- 1..3 do
          BudgetingFactory.insert(:category, book_id: book.id, position: index - 1)
        end

      other_book = BudgetingFactory.insert(:book)
      other_category = BudgetingFactory.insert(:category, book_id: other_book.id)

      %{categories: categories, other_book: other_book, other_category: other_category}
    end

    test "with associated book (authorized scope) returns all book categories ordered by position", %{
      scope: scope,
      book: book,
      categories: categories
    } do
      result = Budgeting.list_categories(scope, book)

      # Categories should be returned ordered by position
      sorted_categories = Enum.sort_by(categories, & &1.position)

      assert length(result) == length(sorted_categories)

      # Verify ordering by position
      result
      |> Enum.zip(sorted_categories)
      |> Enum.each(fn {result_cat, expected_cat} ->
        assert result_cat.id == expected_cat.id
        assert result_cat.position == expected_cat.position
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

    test "with valid data creates an envelope at position 0 and shifts others", %{
      scope: scope,
      book: book,
      category: category
    } do
      # First create some envelopes with known positions
      envelope1 = BudgetingFactory.insert(:envelope, category_id: category.id, position: 0)
      envelope2 = BudgetingFactory.insert(:envelope, category_id: category.id, position: 1)

      attrs = %{name: "new envelope"}

      assert {:ok, new_envelope} = Budgeting.create_envelope(scope, book, category, attrs)
      assert new_envelope.name == "new envelope"
      assert new_envelope.category_id == category.id
      assert new_envelope.position == 0

      # Verify that existing envelopes were shifted down
      reloaded_envelope1 = Repo.reload(envelope1)
      reloaded_envelope2 = Repo.reload(envelope2)

      assert reloaded_envelope1.position == 1
      assert reloaded_envelope2.position == 2
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

  describe "delete_envelope/3" do
    setup %{book: book} do
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)
      %{category: category, envelope: envelope}
    end

    test "with associated envelope, owner role (authorized scope) deletes the envelope", %{
      scope: scope,
      book: book,
      envelope: envelope
    } do
      assert {:ok, %Envelope{}} = Budgeting.delete_envelope(scope, book, envelope)
      assert {:error, :not_found} = Budgeting.fetch_envelope_by_external_id(scope, book, envelope.external_id)
    end

    test "with associated envelope, editor role (authorized scope) deletes the envelope", %{
      book: book,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, %Envelope{}} = Budgeting.delete_envelope(scope, book, envelope)
      assert {:error, :not_found} = Budgeting.fetch_envelope_by_external_id(scope, book, envelope.external_id)
    end

    test "with commenter role (unauthorized scope) returns error", %{
      book: book,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = Budgeting.delete_envelope(scope, book, envelope)
    end

    test "with no association to book (unauthorized scope) returns error", %{
      book: book,
      envelope: envelope
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = Budgeting.delete_envelope(scope, book, envelope)
    end
  end

  describe "reorder_category/4" do
    setup %{book: book} do
      categories =
        Enum.map(0..3, fn position ->
          BudgetingFactory.insert(:category, book_id: book.id, position: position, name: "Category #{position}")
        end)

      %{categories: categories}
    end

    test "reorders a category to a higher position", %{scope: scope, book: book, categories: categories} do
      [category0, category1, category2, category3] = categories

      # Move category0 from position 0 to position 2
      assert {:ok, updated_category} = Budgeting.reorder_category(scope, book, category0, 2)
      assert updated_category.position == 2

      # Reload all categories to see their updated positions
      reloaded_categories = Budgeting.list_categories(scope, book)
      assert length(reloaded_categories) == 4

      # Verify the positions
      assert Enum.find(reloaded_categories, &(&1.id == category1.id)).position == 0
      assert Enum.find(reloaded_categories, &(&1.id == category2.id)).position == 1
      assert Enum.find(reloaded_categories, &(&1.id == category0.id)).position == 2
      assert Enum.find(reloaded_categories, &(&1.id == category3.id)).position == 3
    end

    test "reorders a category to a lower position", %{scope: scope, book: book, categories: categories} do
      [category0, category1, category2, category3] = categories

      # Move category3 from position 3 to position 1
      assert {:ok, updated_category} = Budgeting.reorder_category(scope, book, category3, 1)
      assert updated_category.position == 1

      # Reload all categories to see their updated positions
      reloaded_categories = Budgeting.list_categories(scope, book)
      assert length(reloaded_categories) == 4

      # Verify the positions
      assert Enum.find(reloaded_categories, &(&1.id == category0.id)).position == 0
      assert Enum.find(reloaded_categories, &(&1.id == category3.id)).position == 1
      assert Enum.find(reloaded_categories, &(&1.id == category1.id)).position == 2
      assert Enum.find(reloaded_categories, &(&1.id == category2.id)).position == 3
    end

    test "with invalid position returns error", %{scope: scope, book: book, categories: categories} do
      category = hd(categories)

      assert {:error, :invalid_position} = Budgeting.reorder_category(scope, book, category, -1)
    end

    test "with unauthorized scope returns error", %{book: book, categories: categories} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      category = hd(categories)

      assert {:error, :unauthorized} = Budgeting.reorder_category(scope, book, category, 2)
    end

    test "handles transaction errors gracefully", %{scope: scope, book: book, categories: categories} do
      category = hd(categories)

      # Mock a database error during the transaction
      Mimic.expect(PurseCraft.Repo, :transaction, fn _multi ->
        {:error, :shift_other_categories, :database_error, %{}}
      end)

      assert {:error, :database_error} = Budgeting.reorder_category(scope, book, category, 2)
    end

    test "caps position at maximum available position", %{scope: scope, book: book, categories: categories} do
      category = hd(categories)

      # Try to move category beyond maximum position
      assert {:ok, updated_category} = Budgeting.reorder_category(scope, book, category, 10)
      # Max position is number of categories - 1
      assert updated_category.position == 3
    end
  end

  describe "reorder_envelope/4" do
    setup %{book: book} do
      category = BudgetingFactory.insert(:category, book_id: book.id)

      envelopes =
        Enum.map(0..3, fn position ->
          BudgetingFactory.insert(:envelope, category_id: category.id, position: position, name: "Envelope #{position}")
        end)

      %{category: category, envelopes: envelopes}
    end

    test "reorders an envelope to a higher position", %{scope: scope, book: book, envelopes: envelopes} do
      [envelope0, envelope1, envelope2, envelope3] = envelopes

      # Move envelope0 from position 0 to position 2
      assert {:ok, updated_envelope} = Budgeting.reorder_envelope(scope, book, envelope0, 2)
      assert updated_envelope.position == 2

      # Verify the positions of all envelopes
      reloaded_envelope0 = Repo.reload(envelope0)
      reloaded_envelope1 = Repo.reload(envelope1)
      reloaded_envelope2 = Repo.reload(envelope2)
      reloaded_envelope3 = Repo.reload(envelope3)

      assert reloaded_envelope0.position == 2
      assert reloaded_envelope1.position == 0
      assert reloaded_envelope2.position == 1
      assert reloaded_envelope3.position == 3
    end

    test "reorders an envelope to a lower position", %{scope: scope, book: book, envelopes: envelopes} do
      [envelope0, envelope1, envelope2, envelope3] = envelopes

      # Move envelope3 from position 3 to position 1
      assert {:ok, updated_envelope} = Budgeting.reorder_envelope(scope, book, envelope3, 1)
      assert updated_envelope.position == 1

      # Verify the positions of all envelopes
      reloaded_envelope0 = Repo.reload(envelope0)
      reloaded_envelope1 = Repo.reload(envelope1)
      reloaded_envelope2 = Repo.reload(envelope2)
      reloaded_envelope3 = Repo.reload(envelope3)

      assert reloaded_envelope0.position == 0
      assert reloaded_envelope1.position == 2
      assert reloaded_envelope2.position == 3
      assert reloaded_envelope3.position == 1
    end

    test "with invalid position returns error", %{scope: scope, book: book, envelopes: envelopes} do
      envelope = hd(envelopes)

      assert {:error, :invalid_position} = Budgeting.reorder_envelope(scope, book, envelope, -1)
    end

    test "with unauthorized scope returns error", %{book: book, envelopes: envelopes} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      envelope = hd(envelopes)

      assert {:error, :unauthorized} = Budgeting.reorder_envelope(scope, book, envelope, 2)
    end

    test "handles transaction errors gracefully", %{scope: scope, book: book, envelopes: envelopes} do
      envelope = hd(envelopes)

      # Mock a database error during the transaction
      Mimic.expect(PurseCraft.Repo, :transaction, fn _multi ->
        {:error, :shift_other_envelopes, :database_error, %{}}
      end)

      assert {:error, :database_error} = Budgeting.reorder_envelope(scope, book, envelope, 2)
    end
  end

  describe "move_envelope/5" do
    setup %{book: book} do
      source_category = BudgetingFactory.insert(:category, book_id: book.id, name: "Source Category")
      target_category = BudgetingFactory.insert(:category, book_id: book.id, name: "Target Category")

      # Create envelopes in source category
      source_envelopes =
        Enum.map(0..2, fn position ->
          BudgetingFactory.insert(:envelope,
            category_id: source_category.id,
            position: position,
            name: "Source Envelope #{position}"
          )
        end)

      # Create envelopes in target category
      target_envelopes =
        Enum.map(0..2, fn position ->
          BudgetingFactory.insert(:envelope,
            category_id: target_category.id,
            position: position,
            name: "Target Envelope #{position}"
          )
        end)

      %{
        source_category: source_category,
        target_category: target_category,
        source_envelopes: source_envelopes,
        target_envelopes: target_envelopes
      }
    end

    test "moves an envelope to a different category at specified position", %{
      scope: scope,
      book: book,
      target_category: target_category,
      source_envelopes: source_envelopes,
      target_envelopes: target_envelopes
    } do
      [source_envelope0, source_envelope1, source_envelope2] = source_envelopes
      [target_envelope0, target_envelope1, target_envelope2] = target_envelopes

      # Move source_envelope1 to target_category at position 1
      assert {:ok, moved_envelope} = Budgeting.move_envelope(scope, book, source_envelope1, target_category, 1)
      assert moved_envelope.category_id == target_category.id
      assert moved_envelope.position == 1

      # Verify source category envelopes
      reloaded_source_envelope0 = Repo.reload(source_envelope0)
      reloaded_source_envelope2 = Repo.reload(source_envelope2)

      assert reloaded_source_envelope0.position == 0
      # Position adjusted down
      assert reloaded_source_envelope2.position == 1

      # Verify target category envelopes
      reloaded_target_envelope0 = Repo.reload(target_envelope0)
      reloaded_target_envelope1 = Repo.reload(target_envelope1)
      reloaded_target_envelope2 = Repo.reload(target_envelope2)

      assert reloaded_target_envelope0.position == 0
      # The moved envelope
      assert moved_envelope.position == 1
      # Shifted down
      assert reloaded_target_envelope1.position == 2
      # Shifted down
      assert reloaded_target_envelope2.position == 3
    end

    test "with invalid position returns error", %{
      scope: scope,
      book: book,
      source_envelopes: source_envelopes,
      target_category: target_category
    } do
      envelope = hd(source_envelopes)

      assert {:error, :invalid_position} = Budgeting.move_envelope(scope, book, envelope, target_category, -1)
    end

    test "with unauthorized scope returns error", %{
      book: book,
      source_envelopes: source_envelopes,
      target_category: target_category
    } do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      envelope = hd(source_envelopes)

      assert {:error, :unauthorized} = Budgeting.move_envelope(scope, book, envelope, target_category, 0)
    end

    test "handles transaction errors gracefully", %{
      scope: scope,
      book: book,
      source_envelopes: source_envelopes,
      target_category: target_category
    } do
      envelope = hd(source_envelopes)

      # Mock a database error during the transaction
      Mimic.expect(PurseCraft.Repo, :transaction, fn _multi ->
        {:error, :adjust_source_category, :database_error, %{}}
      end)

      assert {:error, :database_error} = Budgeting.move_envelope(scope, book, envelope, target_category, 0)
    end

    test "uses reorder_envelope when target category is the same as current category", %{
      scope: scope,
      book: book,
      source_envelopes: source_envelopes,
      source_category: source_category
    } do
      envelope = hd(source_envelopes)

      # Make sure we're testing with the correct category
      test_envelope = %{envelope | category_id: source_category.id}

      # This will reorder within the same category
      assert {:ok, updated_envelope} = Budgeting.move_envelope(scope, book, test_envelope, source_category, 2)

      # Verify it called reorder_envelope instead of moving between categories
      assert updated_envelope.category_id == source_category.id
    end
  end
end
