defmodule PurseCraft.Budgeting.Commands.Categories.FetchCategoryByExternalIdTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting.Commands.Categories.FetchCategoryByExternalId
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.IdentityFactory

  setup do
    book = IdentityFactory.insert(:book)
    category = BudgetingFactory.insert(:category, book_id: book.id)

    %{
      book: book,
      category: category
    }
  end

  describe "call/4" do
    test "with valid external_id returns category", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, %Category{} = fetched_category} = FetchCategoryByExternalId.call(scope, book, category.external_id)
      assert fetched_category.id == category.id
      assert fetched_category.name == category.name
    end

    test "with valid external_id and preload option returns category with preloaded associations", %{
      book: book,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      assert {:ok, %Category{} = fetched_category} =
               FetchCategoryByExternalId.call(scope, book, category.external_id, preload: [:envelopes])

      assert fetched_category.id == category.id
      assert length(fetched_category.envelopes) == 1
      assert hd(fetched_category.envelopes).id == envelope.id
    end

    test "with invalid external_id returns not found error", %{book: book} do
      user = IdentityFactory.insert(:user)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :not_found} = FetchCategoryByExternalId.call(scope, book, Ecto.UUID.generate())
    end

    test "with owner role (authorized scope) returns category", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, %Category{}} = FetchCategoryByExternalId.call(scope, book, category.external_id)
    end

    test "with editor role (authorized scope) returns category", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, %Category{}} = FetchCategoryByExternalId.call(scope, book, category.external_id)
    end

    test "with commenter role (authorized scope) returns category", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, %Category{}} = FetchCategoryByExternalId.call(scope, book, category.external_id)
    end

    test "with no association to book (unauthorized scope) returns error", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = FetchCategoryByExternalId.call(scope, book, category.external_id)
    end

    test "with category from different book returns not found", %{category: category} do
      different_book = IdentityFactory.insert(:book)
      user = IdentityFactory.insert(:user)
      IdentityFactory.insert(:book_user, book_id: different_book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :not_found} = FetchCategoryByExternalId.call(scope, different_book, category.external_id)
    end
  end
end
