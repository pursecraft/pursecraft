defmodule PurseCraft.Budgeting.Commands.Books.DeleteBookTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Books.DeleteBook
  alias PurseCraft.Budgeting.Commands.PubSub.BroadcastBook
  alias PurseCraft.Budgeting.Commands.PubSub.BroadcastUserBook
  alias PurseCraft.Budgeting.Schemas.Book
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

  describe "call/2" do
    test "deletes the book successfully", %{scope: scope, book: book} do
      assert {:ok, %Book{}} = DeleteBook.call(scope, book)
      assert Repo.get(Book, book.id) == nil
    end

    test "with non-owner role returns unauthorized error", %{book: book} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = DeleteBook.call(scope, book)
      assert Repo.get(Book, book.id) != nil
    end

    test "with no association to book returns unauthorized error", %{book: book} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = DeleteBook.call(scope, book)
      assert Repo.get(Book, book.id) != nil
    end

    test "broadcasts events when book is deleted successfully", %{scope: scope, book: book} do
      expect(BroadcastUserBook, :call, fn broadcast_scope, {:deleted, broadcast_book} ->
        assert broadcast_scope == scope
        assert broadcast_book.id == book.id
        :ok
      end)

      expect(BroadcastBook, :call, fn broadcast_book, {:deleted, deleted_book} ->
        assert broadcast_book.id == book.id
        assert deleted_book.id == book.id
        :ok
      end)

      assert {:ok, %Book{}} = DeleteBook.call(scope, book)

      verify!()
    end
  end
end
