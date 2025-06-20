defmodule PurseCraft.Accounting.Commands.Accounts.ListAccountsTest do
  use PurseCraft.DataCase, async: true
  use Mimic

  alias PurseCraft.Accounting.Commands.Accounts.ListAccounts
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.AccountingFactory
  alias PurseCraft.IdentityFactory

  setup do
    user = IdentityFactory.insert(:user)
    book = AccountingFactory.insert(:book)
    AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
    scope = IdentityFactory.build(:scope, user: user)

    %{
      user: user,
      scope: scope,
      book: book
    }
  end

  describe "call/3" do
    test "with owner role (authorized scope) returns all book accounts", %{
      scope: scope,
      book: book
    } do
      accounts = [
        AccountingFactory.build(:account, book: book, position: "a"),
        AccountingFactory.build(:account, book: book, position: "b"),
        AccountingFactory.build(:account, book: book, position: "c")
      ]

      stub(AccountRepository, :list_by_book, fn book_id, opts ->
        assert book_id == book.id
        assert opts == []
        accounts
      end)

      result = ListAccounts.call(scope, book)

      assert result == accounts
    end

    test "with preload option returns accounts with associations", %{
      scope: scope,
      book: book
    } do
      accounts = [AccountingFactory.build(:account, book: book)]

      stub(AccountRepository, :list_by_book, fn book_id, opts ->
        assert book_id == book.id
        assert opts == [preload: [:book]]
        accounts
      end)

      result = ListAccounts.call(scope, book, preload: [:book])

      assert result == accounts
    end

    test "with editor role (authorized scope) returns accounts", %{book: book} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      accounts = [AccountingFactory.build(:account, book: book)]

      stub(AccountRepository, :list_by_book, fn _book_id, _opts -> accounts end)

      result = ListAccounts.call(scope, book)

      assert result == accounts
    end

    test "with commenter role (authorized scope) returns accounts", %{book: book} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      accounts = [AccountingFactory.build(:account, book: book)]

      stub(AccountRepository, :list_by_book, fn _book_id, _opts -> accounts end)

      result = ListAccounts.call(scope, book)

      assert result == accounts
    end

    test "with no association to book (unauthorized scope) returns error", %{book: book} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      # Repository should not be called due to authorization failure
      reject(AccountRepository, :list_by_book, 2)

      assert {:error, :unauthorized} = ListAccounts.call(scope, book)
    end

    test "with active_only option filters accounts", %{scope: scope, book: book} do
      accounts = [AccountingFactory.build(:account, book: book)]

      stub(AccountRepository, :list_by_book, fn book_id, opts ->
        assert book_id == book.id
        assert opts == [active_only: false]
        accounts
      end)

      result = ListAccounts.call(scope, book, active_only: false)

      assert result == accounts
    end
  end
end
