defmodule PurseCraft.Budgeting.Commands.Categories.UpdateCategoryTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Categories.UpdateCategory
  alias PurseCraft.Budgeting.Repositories.CategoryRepository
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastBook

  setup do
    book = BudgetingFactory.insert(:book)
    category = BudgetingFactory.insert(:category, book_id: book.id)

    %{
      book: book,
      category: category
    }
  end

  describe "call/5" do
    test "with string keys in attrs calls repository update correctly", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      updated_category = %{category | name: "Updated String Key Category"}
      attrs = %{"name" => "Updated String Key Category"}

      stub(CategoryRepository, :update, fn received_category, received_attrs, received_opts ->
        assert received_category.id == category.id
        assert received_attrs == %{name: "Updated String Key Category"}
        assert received_opts == []
        {:ok, updated_category}
      end)

      assert {:ok, %Category{} = result} = UpdateCategory.call(scope, book, category, attrs)
      assert result.name == "Updated String Key Category"
    end

    test "with authorization failure returns unauthorized error", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Updated Category"}

      reject(CategoryRepository, :update, 3)

      assert {:error, :unauthorized} = UpdateCategory.call(scope, book, category, attrs)
    end

    test "with repository error returns changeset error", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: ""}
      changeset = Category.changeset(category, attrs)

      stub(CategoryRepository, :update, fn _category, _attrs, _opts ->
        {:error, changeset}
      end)

      assert {:error, returned_changeset} = UpdateCategory.call(scope, book, category, attrs)
      assert returned_changeset == changeset
    end

    test "with preload option preloads associations", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      updated_category = %{category | name: "Updated Category"}
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      stub(CategoryRepository, :update, fn _category, _attrs, received_opts ->
        assert received_opts == [preload: [:envelopes]]
        {:ok, %{updated_category | envelopes: [envelope]}}
      end)

      attrs = %{name: "Updated Category"}

      assert {:ok, %Category{} = result} = UpdateCategory.call(scope, book, category, attrs, preload: [:envelopes])
      assert result.name == "Updated Category"
      assert Enum.any?(result.envelopes, &(&1.id == envelope.id))
    end

    test "without preload option returns category without loaded associations", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      updated_category = %{category | name: "Updated Category"}

      stub(CategoryRepository, :update, fn _category, _attrs, received_opts ->
        assert received_opts == []
        {:ok, updated_category}
      end)

      attrs = %{name: "Updated Category"}

      assert {:ok, %Category{} = result} = UpdateCategory.call(scope, book, category, attrs)
      refute Ecto.assoc_loaded?(result.envelopes)
    end

    test "invokes BroadcastBook with correct parameters", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      updated_category = %{category | name: "Broadcast Test Category"}

      expect(CategoryRepository, :update, fn _category, _attrs, _opts ->
        {:ok, updated_category}
      end)

      expect(BroadcastBook, :call, fn received_book, {:category_updated, received_category} ->
        assert received_book.id == book.id
        assert received_category.id == updated_category.id
        assert received_category.name == "Broadcast Test Category"
        :ok
      end)

      attrs = %{name: "Broadcast Test Category"}

      assert {:ok, %Category{}} = UpdateCategory.call(scope, book, category, attrs)

      verify!()
    end
  end
end
