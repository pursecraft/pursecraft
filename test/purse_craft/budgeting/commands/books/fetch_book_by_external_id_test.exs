defmodule PurseCraft.Budgeting.Commands.Books.FetchBookByExternalIdTest do
  use PurseCraft.DataCase, async: true
  use Mimic

  alias PurseCraft.Budgeting.Commands.Books.FetchBookByExternalId
  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

  describe "call/3" do
    test "with associated book (authorized scope) returns ok tuple with book" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      book = CoreFactory.insert(:book)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      assert {:ok, returned_book} = FetchBookByExternalId.call(scope, book.external_id)
      assert returned_book.id == book.id
    end

    test "supports preloading associations" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      book = CoreFactory.insert(:book)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      category1 = BudgetingFactory.insert(:category, book_id: book.id, position: "g")
      category2 = BudgetingFactory.insert(:category, book_id: book.id, position: "m")

      assert {:ok, book_with_preloads} =
               FetchBookByExternalId.call(scope, book.external_id, preload: [:categories])

      assert Enum.count(book_with_preloads.categories) == 2
      assert Enum.any?(book_with_preloads.categories, &(&1.id == category1.id))
      assert Enum.any?(book_with_preloads.categories, &(&1.id == category2.id))
    end

    test "with non-existent book returns error tuple" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      non_existent_id = Ecto.UUID.generate()

      expect(Policy, :authorize, fn :book_read, _scope, _params -> :ok end)

      assert {:error, :not_found} = FetchBookByExternalId.call(scope, non_existent_id)
    end

    test "with unauthorized scope returns error tuple" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      book = CoreFactory.insert(:book)

      assert {:error, :unauthorized} = FetchBookByExternalId.call(scope, book.external_id)
    end
  end
end
