defmodule PurseCraft.Accounting.Commands.Accounts.FetchAccountByExternalIdTest do
  use PurseCraft.DataCase, async: true
  use Mimic

  alias PurseCraft.Accounting.Commands.Accounts.FetchAccountByExternalId
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.AccountingFactory
  alias PurseCraft.IdentityFactory

  setup do
    book = IdentityFactory.insert(:book)
    account = AccountingFactory.insert(:account, book: book)
    user = IdentityFactory.insert(:user)

    %{
      book: book,
      account: account,
      user: user
    }
  end

  describe "call/4" do
    test "with owner role (authorized scope) returns account", %{book: book, account: account, user: user} do
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      stub(AccountRepository, :get_by_external_id, fn book_id, external_id, opts ->
        assert book_id == book.id
        assert external_id == account.external_id
        assert opts == []
        account
      end)

      assert {:ok, ^account} = FetchAccountByExternalId.call(scope, book, account.external_id)
    end

    test "with invalid external_id returns not found error", %{book: book, user: user} do
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)
      invalid_uuid = Ecto.UUID.generate()

      stub(AccountRepository, :get_by_external_id, fn book_id, external_id, opts ->
        assert book_id == book.id
        assert external_id == invalid_uuid
        assert opts == []
        nil
      end)

      assert {:error, :not_found} = FetchAccountByExternalId.call(scope, book, invalid_uuid)
    end

    test "with editor role (authorized scope) returns account", %{book: book, account: account, user: user} do
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      stub(AccountRepository, :get_by_external_id, fn _book_id, _external_id, _opts -> account end)

      assert {:ok, ^account} = FetchAccountByExternalId.call(scope, book, account.external_id)
    end

    test "with commenter role (authorized scope) returns account", %{book: book, account: account, user: user} do
      IdentityFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      stub(AccountRepository, :get_by_external_id, fn _book_id, _external_id, _opts -> account end)

      assert {:ok, ^account} = FetchAccountByExternalId.call(scope, book, account.external_id)
    end

    test "with no association to book (unauthorized scope) returns error", %{book: book, account: account, user: user} do
      scope = IdentityFactory.build(:scope, user: user)

      # Repository should not be called due to authorization failure
      reject(AccountRepository, :get_by_external_id, 3)

      assert {:error, :unauthorized} = FetchAccountByExternalId.call(scope, book, account.external_id)
    end

    test "with account from different book returns not found", %{account: account, user: user} do
      different_book = IdentityFactory.insert(:book)
      IdentityFactory.insert(:book_user, book_id: different_book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      stub(AccountRepository, :get_by_external_id, fn book_id, external_id, opts ->
        assert book_id == different_book.id
        assert external_id == account.external_id
        assert opts == []
        nil
      end)

      assert {:error, :not_found} = FetchAccountByExternalId.call(scope, different_book, account.external_id)
    end
  end
end
