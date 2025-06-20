defmodule PurseCraft.Accounting.Commands.Accounts.CloseAccountTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Accounting.Commands.Accounts.CloseAccount
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.AccountingFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastBook

  setup do
    book = AccountingFactory.insert(:book)
    account = AccountingFactory.insert(:account, book: book)

    %{
      book: book,
      account: account
    }
  end

  describe "call/3" do
    test "with owner role (authorized scope) closes an account", %{book: book, account: account} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, %Account{} = closed_account} = CloseAccount.call(scope, book, account.external_id)
      assert closed_account.external_id == account.external_id
      assert not is_nil(closed_account.closed_at)
    end

    test "with editor role (authorized scope) closes an account", %{book: book, account: account} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, %Account{} = closed_account} = CloseAccount.call(scope, book, account.external_id)
      assert closed_account.external_id == account.external_id
      assert not is_nil(closed_account.closed_at)
    end

    test "with commenter role (unauthorized scope) returns authorization error", %{book: book, account: account} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = CloseAccount.call(scope, book, account.external_id)
    end

    test "with non-existent account returns not found error", %{book: book} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :not_found} = CloseAccount.call(scope, book, Ecto.UUID.generate())
    end

    test "invokes BroadcastBook when account is closed successfully", %{book: book, account: account} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      expect(BroadcastBook, :call, fn broadcast_book, {:account_closed, broadcast_account} ->
        assert broadcast_book == book
        assert broadcast_account.external_id == account.external_id
        assert not is_nil(broadcast_account.closed_at)
        :ok
      end)

      assert {:ok, %Account{}} = CloseAccount.call(scope, book, account.external_id)

      verify!()
    end
  end
end
