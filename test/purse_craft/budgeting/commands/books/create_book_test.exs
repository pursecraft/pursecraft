defmodule PurseCraft.Budgeting.Commands.Books.CreateBookTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Books.CreateBook
  alias PurseCraft.Core.Schemas.Book
  alias PurseCraft.Core.Schemas.BookUser
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastUserBook
  alias PurseCraft.Repo

  setup do
    user = IdentityFactory.insert(:user)
    scope = IdentityFactory.build(:scope, user: user)

    %{
      user: user,
      scope: scope
    }
  end

  describe "call/2" do
    test "with valid data creates a book", %{scope: scope} do
      attrs = %{name: "Test Command Book"}

      assert {:ok, %Book{} = book} = CreateBook.call(scope, attrs)
      assert book.name == "Test Command Book"

      book_user = Repo.get_by(BookUser, book_id: book.id)
      assert book_user.user_id == scope.user.id
      assert book_user.role == :owner
    end

    test "with invalid data returns error changeset", %{scope: scope} do
      attrs = %{name: ""}

      assert {:error, changeset} = CreateBook.call(scope, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with unauthorized scope returns error" do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      # This doesn't actually happen in reality since all users are allowed to create
      # `Book` records, so we are mocking this response to see if this branch of the
      # business logic actually works.
      expect(PurseCraft.Budgeting.Policy, :authorize, fn :book_create, _scope ->
        {:error, :unauthorized}
      end)

      attrs = %{name: "Unauthorized Book"}

      assert {:error, :unauthorized} = CreateBook.call(scope, attrs)
    end

    test "Invokes BroadcastUserBook when book is created successfully", %{scope: scope} do
      expect(BroadcastUserBook, :call, fn broadcast_scope, {:created, broadcast_book} ->
        assert broadcast_scope == scope
        assert broadcast_book.name == "Broadcast Test Book"
        :ok
      end)

      attrs = %{name: "Broadcast Test Book"}

      assert {:ok, %Book{}} = CreateBook.call(scope, attrs)

      verify!()
    end
  end
end
