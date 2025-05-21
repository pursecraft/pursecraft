defmodule PurseCraft.Budgeting.Commands.Categories.CreateCategoryTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Categories.CreateCategory
  alias PurseCraft.Budgeting.Commands.PubSub.BroadcastBook
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.IdentityFactory

  setup do
    book = BudgetingFactory.insert(:book)

    %{
      book: book
    }
  end

  describe "call/3" do
    test "with string keys in attrs creates a category correctly", %{book: book} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{"name" => "String Key Category"}

      assert {:ok, %Category{} = category} = CreateCategory.call(scope, book, attrs)
      assert category.name == "String Key Category"
      assert category.book_id == book.id
    end

    test "with invalid data returns error changeset", %{book: book} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: ""}

      assert {:error, changeset} = CreateCategory.call(scope, book, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with owner role (authorized scope) creates a category", %{book: book} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Owner Category"}

      assert {:ok, %Category{} = category} = CreateCategory.call(scope, book, attrs)
      assert category.name == "Owner Category"
      assert category.book_id == book.id
    end

    test "with editor role (authorized scope) creates a category", %{book: book} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Editor Category"}

      assert {:ok, %Category{} = category} = CreateCategory.call(scope, book, attrs)
      assert category.name == "Editor Category"
      assert category.book_id == book.id
    end

    test "with commenter role (unauthorized scope) returns error", %{book: book} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
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
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
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
  end
end
