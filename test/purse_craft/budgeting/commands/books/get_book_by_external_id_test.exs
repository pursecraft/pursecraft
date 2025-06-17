defmodule PurseCraft.Budgeting.Commands.Books.GetBookByExternalIdTest do
  use PurseCraft.DataCase, async: true
  use Mimic

  alias PurseCraft.Budgeting.Commands.Books.GetBookByExternalId
  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.IdentityFactory

  describe "call!/2" do
    test "with associated book (authorized scope) returns book" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      book = BudgetingFactory.insert(:book)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      result = GetBookByExternalId.call!(scope, book.external_id)
      assert result.id == book.id
      assert result.external_id == book.external_id
      assert result.name == book.name
    end

    test "with no associated books (unauthorized scope) raises `LetMe.UnauthorizedError`" do
      assert_raise LetMe.UnauthorizedError, fn ->
        user = IdentityFactory.insert(:user)
        scope = IdentityFactory.build(:scope, user: user)
        book = BudgetingFactory.insert(:book)

        GetBookByExternalId.call!(scope, book.external_id)
      end
    end

    test "with non-existent book raises `Ecto.NoResultsError`" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      non_existent_id = Ecto.UUID.generate()

      expect(Policy, :authorize!, fn :book_read, _scope, _params -> :ok end)

      assert_raise Ecto.NoResultsError, fn ->
        GetBookByExternalId.call!(scope, non_existent_id)
      end
    end
  end
end
