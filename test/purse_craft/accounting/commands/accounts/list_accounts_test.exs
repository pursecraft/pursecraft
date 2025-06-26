defmodule PurseCraft.Accounting.Commands.Accounts.ListAccountsTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Accounting.Commands.Accounts.ListAccounts
  alias PurseCraft.AccountingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

  setup do
    user = IdentityFactory.insert(:user)
    book = CoreFactory.insert(:book)
    CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
    scope = IdentityFactory.build(:scope, user: user)

    {:ok, user: user, book: book, scope: scope}
  end

  describe "call/3" do
    test "with owner role (authorized scope) returns all book accounts", %{
      scope: scope,
      book: book
    } do
      account1 = AccountingFactory.insert(:account, book: book, position: "aaaa")
      account2 = AccountingFactory.insert(:account, book: book, position: "bbbb")

      accounts = ListAccounts.call(scope, book)
      assert length(accounts) == 2
      assert [first_account, second_account] = accounts
      assert first_account.id == account1.id
      assert second_account.id == account2.id
    end

    test "with editor role (authorized scope) returns accounts", %{book: book} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)
      AccountingFactory.insert(:account, book: book, position: "aaaa")

      accounts = ListAccounts.call(scope, book)
      assert length(accounts) == 1
    end

    test "with commenter role (authorized scope) returns accounts", %{book: book} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)
      AccountingFactory.insert(:account, book: book, position: "aaaa")

      accounts = ListAccounts.call(scope, book)
      assert length(accounts) == 1
    end

    test "returns empty list when no accounts exist", %{scope: scope, book: book} do
      accounts = ListAccounts.call(scope, book)
      assert accounts == []
    end

    test "returns accounts ordered by position", %{scope: scope, book: book} do
      account1 = AccountingFactory.insert(:account, book: book, position: "bbbb")
      account2 = AccountingFactory.insert(:account, book: book, position: "aaaa")

      accounts = ListAccounts.call(scope, book)
      assert [first_account, second_account] = accounts
      assert first_account.id == account2.id
      assert second_account.id == account1.id
    end

    test "excludes closed accounts by default", %{scope: scope, book: book} do
      AccountingFactory.insert(:account, book: book, position: "aaaa")
      AccountingFactory.insert(:account, book: book, position: "bbbb", closed_at: DateTime.utc_now())

      accounts = ListAccounts.call(scope, book)
      assert length(accounts) == 1
    end

    test "with no association to book (unauthorized scope) returns error", %{book: book} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = ListAccounts.call(scope, book)
    end

    test "returns only accounts for the specified book", %{scope: scope, book: book} do
      other_book = CoreFactory.insert(:book)
      AccountingFactory.insert(:account, book: book, position: "aaaa")
      AccountingFactory.insert(:account, book: other_book, position: "aaaa")

      accounts = ListAccounts.call(scope, book)
      assert length(accounts) == 1
    end
  end
end
