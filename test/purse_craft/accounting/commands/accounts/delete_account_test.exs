defmodule PurseCraft.Accounting.Commands.Accounts.DeleteAccountTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Accounting.Commands.Accounts.DeleteAccount
  alias PurseCraft.AccountingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

  setup do
    user = IdentityFactory.insert(:user)
    book = CoreFactory.insert(:book)
    scope = IdentityFactory.build(:scope, user: user)

    {:ok, user: user, book: book, scope: scope}
  end

  describe "call/3" do
    test "with owner role (authorized scope) deletes account successfully", %{
      user: user,
      scope: scope,
      book: book
    } do
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      account = AccountingFactory.insert(:account, book: book)

      assert {:ok, deleted_account} = DeleteAccount.call(scope, book, account.external_id)
      assert deleted_account.id == account.id
    end

    test "with editor role (authorized scope) deletes account successfully", %{book: book} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)
      account = AccountingFactory.insert(:account, book: book)

      assert {:ok, deleted_account} = DeleteAccount.call(scope, book, account.external_id)
      assert deleted_account.id == account.id
    end

    test "with commenter role (unauthorized scope) returns error", %{book: book} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)
      account = AccountingFactory.insert(:account, book: book)

      assert {:error, :unauthorized} = DeleteAccount.call(scope, book, account.external_id)
    end

    test "with invalid external_id returns not found error", %{user: user, scope: scope, book: book} do
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      assert {:error, :not_found} = DeleteAccount.call(scope, book, Ecto.UUID.generate())
    end
  end
end
