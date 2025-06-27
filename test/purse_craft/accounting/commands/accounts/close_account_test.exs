defmodule PurseCraft.Accounting.Commands.Accounts.CloseAccountTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Accounting.Commands.Accounts.CloseAccount
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
    test "with owner role (authorized scope) closes account successfully", %{
      user: user,
      scope: scope,
      book: book
    } do
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      account = AccountingFactory.insert(:account, book: book, closed_at: nil)

      assert {:ok, closed_account} = CloseAccount.call(scope, book, account.external_id)
      assert closed_account.id == account.id
      assert closed_account.closed_at != nil
    end

    test "with editor role (authorized scope) closes account successfully", %{book: book} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)
      account = AccountingFactory.insert(:account, book: book, closed_at: nil)

      assert {:ok, closed_account} = CloseAccount.call(scope, book, account.external_id)
      assert closed_account.id == account.id
      assert closed_account.closed_at != nil
    end

    test "with commenter role (unauthorized scope) returns error", %{book: book} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)
      account = AccountingFactory.insert(:account, book: book)

      assert {:error, :unauthorized} = CloseAccount.call(scope, book, account.external_id)
    end

    test "with no association to book (unauthorized scope) returns error", %{book: book} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)
      account = AccountingFactory.insert(:account, book: book)

      assert {:error, :unauthorized} = CloseAccount.call(scope, book, account.external_id)
    end

    test "with invalid external_id returns not found error", %{user: user, scope: scope, book: book} do
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      assert {:error, :not_found} = CloseAccount.call(scope, book, Ecto.UUID.generate())
    end
  end
end
