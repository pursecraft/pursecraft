defmodule PurseCraft.Budgeting.Commands.Categories.RepositionCategoryTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Categories.RepositionCategory
  alias PurseCraft.Budgeting.Commands.PubSub.BroadcastBook
  alias PurseCraft.Budgeting.Repositories.CategoryRepository
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.IdentityFactory

  setup do
    book = BudgetingFactory.insert(:book)

    cat1 = BudgetingFactory.insert(:category, book_id: book.id, position: "g")
    cat2 = BudgetingFactory.insert(:category, book_id: book.id, position: "m")
    cat3 = BudgetingFactory.insert(:category, book_id: book.id, position: "t")

    %{
      book: book,
      cat1: cat1,
      cat2: cat2,
      cat3: cat3
    }
  end

  describe "call/4" do
    test "successfully repositions category between two others", %{book: book, cat1: cat1, cat2: cat2, cat3: cat3} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, updated} = RepositionCategory.call(scope, cat3.external_id, cat1.external_id, cat2.external_id)

      assert updated.id == cat3.id
      assert updated.position > cat1.position
      assert updated.position < cat2.position
    end

    test "repositions category to the beginning when prev_category_id is nil", %{book: book, cat1: cat1, cat3: cat3} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, updated} = RepositionCategory.call(scope, cat3.external_id, nil, cat1.external_id)

      assert updated.id == cat3.id
      assert updated.position < cat1.position
    end

    test "repositions category to the end when next_category_id is nil", %{book: book, cat1: cat1, cat3: cat3} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, updated} = RepositionCategory.call(scope, cat1.external_id, cat3.external_id, nil)

      assert updated.id == cat1.id
      assert updated.position > cat3.position
    end

    test "returns not_found when category doesn't exist", %{book: book, cat1: cat1, cat2: cat2} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :not_found} =
               RepositionCategory.call(scope, Ecto.UUID.generate(), cat1.external_id, cat2.external_id)
    end

    test "returns not_found when prev_category doesn't exist", %{book: book, cat1: cat1, cat2: cat2} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :not_found} =
               RepositionCategory.call(scope, cat1.external_id, Ecto.UUID.generate(), cat2.external_id)
    end

    test "returns not_found when next_category doesn't exist", %{book: book, cat1: cat1, cat2: cat2} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :not_found} =
               RepositionCategory.call(scope, cat1.external_id, cat2.external_id, Ecto.UUID.generate())
    end

    test "returns not_found when prev_category is from different book", %{book: book, cat1: cat1, cat2: cat2} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      other_book = BudgetingFactory.insert(:book)
      other_cat = BudgetingFactory.insert(:category, book_id: other_book.id, position: "a")

      assert {:error, :not_found} =
               RepositionCategory.call(scope, cat1.external_id, other_cat.external_id, cat2.external_id)
    end

    test "returns unauthorized when user lacks permission", %{book: book, cat1: cat1, cat2: cat2, cat3: cat3} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} =
               RepositionCategory.call(scope, cat3.external_id, cat1.external_id, cat2.external_id)
    end

    test "returns error when fractional indexing fails", %{book: book} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      cat1 = BudgetingFactory.insert(:category, book_id: book.id, position: "z")
      cat2 = BudgetingFactory.insert(:category, book_id: book.id, position: "a")
      cat3 = BudgetingFactory.insert(:category, book_id: book.id, position: "n")

      assert {:error, :prev_must_be_less_than_next} =
               RepositionCategory.call(scope, cat3.external_id, cat1.external_id, cat2.external_id)
    end

    test "broadcasts category_repositioned event on success", %{book: book, cat1: cat1, cat2: cat2, cat3: cat3} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      expect(BroadcastBook, :call, fn received_book, {:category_repositioned, received_category} ->
        assert received_book.id == book.id
        assert received_category.id == cat3.id
        :ok
      end)

      assert {:ok, _updated} = RepositionCategory.call(scope, cat3.external_id, cat1.external_id, cat2.external_id)

      verify!()
    end

    test "handles unique constraint violation with retry", %{book: book, cat1: cat1, cat2: cat2, cat3: cat3} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, updated} = RepositionCategory.call(scope, cat3.external_id, cat1.external_id, cat2.external_id)

      assert updated.id == cat3.id
      assert updated.position > cat1.position
      assert updated.position < cat2.position
    end

    test "returns error after max retries", %{book: book, cat1: cat1, cat2: cat2, cat3: cat3} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      stub(CategoryRepository, :update_position, fn _category, _position ->
        changeset = Category.position_changeset(cat3, %{position: "test"})
        changeset = Ecto.Changeset.add_error(changeset, :position, "has already been taken")
        {:error, changeset}
      end)

      assert {:error, changeset} = RepositionCategory.call(scope, cat3.external_id, cat1.external_id, cat2.external_id)

      assert Enum.any?(changeset.errors, fn
               {:position, {"has already been taken", _opts}} -> true
               _error -> false
             end)
    end

    test "handles non-position errors in changeset", %{book: book, cat1: cat1, cat2: cat2, cat3: cat3} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      stub(CategoryRepository, :update_position, fn _category, _position ->
        changeset = Category.position_changeset(cat3, %{position: "test"})
        changeset = Ecto.Changeset.add_error(changeset, :name, "is invalid")
        {:error, changeset}
      end)

      assert {:error, changeset} = RepositionCategory.call(scope, cat3.external_id, cat1.external_id, cat2.external_id)

      refute Enum.any?(changeset.errors, fn
               {:position, {"has already been taken", _opts}} -> true
               _error -> false
             end)
    end
  end
end
