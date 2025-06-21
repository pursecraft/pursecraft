defmodule PurseCraft.Budgeting.Commands.Categories.CreateCategoryTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Categories.CreateCategory
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastBook

  setup do
    book = IdentityFactory.insert(:book)

    %{
      book: book
    }
  end

  describe "call/3" do
    test "with string keys in attrs creates a category correctly", %{book: book} do
      user = IdentityFactory.insert(:user)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{"name" => "String Key Category"}

      assert {:ok, %Category{} = category} = CreateCategory.call(scope, book, attrs)
      assert category.name == "String Key Category"
      assert category.book_id == book.id
      assert category.position == "m"
    end

    test "with invalid data returns error changeset", %{book: book} do
      user = IdentityFactory.insert(:user)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: ""}

      assert {:error, changeset} = CreateCategory.call(scope, book, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with owner role (authorized scope) creates a category", %{book: book} do
      user = IdentityFactory.insert(:user)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Owner Category"}

      assert {:ok, %Category{} = category} = CreateCategory.call(scope, book, attrs)
      assert category.name == "Owner Category"
      assert category.book_id == book.id
    end

    test "with editor role (authorized scope) creates a category", %{book: book} do
      user = IdentityFactory.insert(:user)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Editor Category"}

      assert {:ok, %Category{} = category} = CreateCategory.call(scope, book, attrs)
      assert category.name == "Editor Category"
      assert category.book_id == book.id
    end

    test "with commenter role (unauthorized scope) returns error", %{book: book} do
      user = IdentityFactory.insert(:user)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Commenter Category"}

      assert {:error, :unauthorized} = CreateCategory.call(scope, book, attrs)
    end

    test "with no association to book (unauthorized scope) returns error", %{book: book} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Unauthorized Category"}

      assert {:error, :unauthorized} = CreateCategory.call(scope, book, attrs)
    end

    test "invokes BroadcastBook when category is created successfully", %{book: book} do
      user = IdentityFactory.insert(:user)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      expect(BroadcastBook, :call, fn broadcast_book, {:category_created, broadcast_category} ->
        assert broadcast_book == book
        assert broadcast_category.name == "Broadcast Test Category"
        :ok
      end)

      attrs = %{name: "Broadcast Test Category"}

      assert {:ok, %Category{}} = CreateCategory.call(scope, book, attrs)

      verify!()
    end

    test "assigns position 'm' for first category in a book", %{book: book} do
      user = IdentityFactory.insert(:user)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "First Category"}

      assert {:ok, %Category{} = category} = CreateCategory.call(scope, book, attrs)
      assert category.position == "m"
    end

    test "assigns position before existing categories", %{book: book} do
      user = IdentityFactory.insert(:user)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      # Create first category
      BudgetingFactory.insert(:category, book: book, position: "m")

      attrs = %{name: "Second Category"}

      assert {:ok, %Category{} = category} = CreateCategory.call(scope, book, attrs)
      assert category.position < "m"
      assert category.position == "g"
    end

    test "handles multiple categories being added at the top", %{book: book} do
      user = IdentityFactory.insert(:user)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      # Create initial categories
      BudgetingFactory.insert(:category, book: book, position: "g")
      BudgetingFactory.insert(:category, book: book, position: "m")
      BudgetingFactory.insert(:category, book: book, position: "t")

      attrs = %{name: "New Top Category"}

      assert {:ok, %Category{} = category} = CreateCategory.call(scope, book, attrs)
      assert category.position < "g"
      assert category.position == "d"
    end

    test "returns error when first category is already at 'a'", %{book: book} do
      user = IdentityFactory.insert(:user)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      # Create a category at the boundary
      BudgetingFactory.insert(:category, book: book, position: "a")

      attrs = %{name: "Cannot Place At Top"}

      assert {:error, :cannot_place_at_top} = CreateCategory.call(scope, book, attrs)
    end
  end
end
