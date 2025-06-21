defmodule PurseCraft.Budgeting.Commands.Books.UpdateBookTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Books.UpdateBook
  alias PurseCraft.Budgeting.Commands.PubSub.BroadcastUserBook
  alias PurseCraft.Identity.Schemas.Book
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastBook

  setup do
    user = IdentityFactory.insert(:user)
    book = IdentityFactory.insert(:book)
    IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
    scope = IdentityFactory.build(:scope, user: user)

    %{
      user: user,
      scope: scope,
      book: book
    }
  end

  describe "call/3" do
    test "with valid data updates the book", %{scope: scope, book: book} do
      attrs = %{name: "Updated Book Name"}

      assert {:ok, %Book{} = updated_book} = UpdateBook.call(scope, book, attrs)
      assert updated_book.name == "Updated Book Name"
    end

    test "with invalid data returns error changeset", %{scope: scope, book: book} do
      attrs = %{name: ""}

      assert {:error, changeset} = UpdateBook.call(scope, book, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with non-owner role returns unauthorized error", %{book: book} do
      user = IdentityFactory.insert(:user)
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Editor Updated Name"}

      assert {:error, :unauthorized} = UpdateBook.call(scope, book, attrs)
    end

    test "with no association to book returns unauthorized error", %{book: book} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Unauthorized Update"}

      assert {:error, :unauthorized} = UpdateBook.call(scope, book, attrs)
    end

    test "broadcasts events when book is updated successfully", %{scope: scope, book: book} do
      expect(BroadcastUserBook, :call, fn broadcast_scope, {:updated, broadcast_book} ->
        assert broadcast_scope == scope
        assert broadcast_book.id == book.id
        assert broadcast_book.name == "Broadcasted Book Name"
        :ok
      end)

      expect(BroadcastBook, :call, fn broadcast_book, {:updated, updated_book} ->
        assert broadcast_book.id == book.id
        assert updated_book.id == book.id
        assert updated_book.name == "Broadcasted Book Name"
        :ok
      end)

      attrs = %{name: "Broadcasted Book Name"}

      assert {:ok, %Book{}} = UpdateBook.call(scope, book, attrs)

      verify!()
    end
  end
end
