defmodule PurseCraft.Accounting.Commands.Accounts.FetchAccountByExternalIdTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Accounting.Commands.Accounts.FetchAccountByExternalId
  alias PurseCraft.AccountingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

  describe "call/4" do
    setup do
      user = IdentityFactory.insert(:user)
      book = CoreFactory.insert(:book)
      scope = IdentityFactory.build(:scope, user: user)

      {:ok, user: user, book: book, scope: scope}
    end

    test "returns account when user is owner", %{user: user, book: book, scope: scope} do
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      account = AccountingFactory.insert(:account, book: book)

      assert {:ok, fetched_account} = FetchAccountByExternalId.call(scope, book, account.external_id)
      assert fetched_account.id == account.id
      assert fetched_account.external_id == account.external_id
    end

    test "returns account when user is editor", %{user: user, book: book, scope: scope} do
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      account = AccountingFactory.insert(:account, book: book)

      assert {:ok, fetched_account} = FetchAccountByExternalId.call(scope, book, account.external_id)
      assert fetched_account.id == account.id
    end

    test "returns account when user is commenter", %{user: user, book: book, scope: scope} do
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      account = AccountingFactory.insert(:account, book: book)

      assert {:ok, fetched_account} = FetchAccountByExternalId.call(scope, book, account.external_id)
      assert fetched_account.id == account.id
    end

    test "returns error when account not found", %{user: user, book: book, scope: scope} do
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)

      assert {:error, :not_found} = FetchAccountByExternalId.call(scope, book, Ecto.UUID.generate())
    end

    test "returns error when user has no access to book", %{user: user, book: book, scope: scope} do
      other_book = CoreFactory.insert(:book)
      CoreFactory.insert(:book_user, book_id: other_book.id, user_id: user.id, role: :owner)
      account = AccountingFactory.insert(:account, book: book)

      assert {:error, :unauthorized} = FetchAccountByExternalId.call(scope, book, account.external_id)
    end

    test "passes options to fetch account with preload", %{user: user, book: book, scope: scope} do
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      account = AccountingFactory.insert(:account, book: book)
      opts = [preload: [:book]]

      assert {:ok, fetched_account} = FetchAccountByExternalId.call(scope, book, account.external_id, opts)
      assert fetched_account.id == account.id
      assert %Ecto.Association.NotLoaded{} != fetched_account.book
    end
  end
end
