defmodule PurseCraft.Accounting.Commands.Accounts.DeleteAccountTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Accounting.Commands.Accounts.DeleteAccount
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
    test "with owner role (authorized scope) deletes an account", %{book: book, account: account} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, %Account{} = deleted_account} = DeleteAccount.call(scope, book, account.external_id)
      assert deleted_account.external_id == account.external_id
    end

    test "with editor role (authorized scope) deletes an account", %{book: book, account: account} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, %Account{}} = DeleteAccount.call(scope, book, account.external_id)
    end

    test "with commenter role (unauthorized scope) returns error", %{book: book, account: account} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = DeleteAccount.call(scope, book, account.external_id)
    end

    test "with no association to book (unauthorized scope) returns error", %{book: book, account: account} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = DeleteAccount.call(scope, book, account.external_id)
    end

    test "invokes BroadcastBook when account is deleted successfully", %{book: book, account: account} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      expect(BroadcastBook, :call, fn broadcast_book, {:account_deleted, broadcast_account} ->
        assert broadcast_book == book
        assert broadcast_account.external_id == account.external_id
        :ok
      end)

      assert {:ok, %Account{}} = DeleteAccount.call(scope, book, account.external_id)

      verify!()
    end
  end
end
