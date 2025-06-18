defmodule PurseCraft.Accounting.Commands.Accounts.CreateAccountTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Accounting.Commands.Accounts.CreateAccount
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.AccountingFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastBook

  setup do
    book = AccountingFactory.insert(:book)

    %{
      book: book
    }
  end

  describe "call/3" do
    test "with string keys in attrs creates an account correctly", %{book: book} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{"name" => "String Key Account", "account_type" => "checking"}

      assert {:ok, %Account{} = account} = CreateAccount.call(scope, book, attrs)
      assert account.name == "String Key Account"
      assert account.account_type == "checking"
      assert account.book_id == book.id
      assert account.position == "m"
    end

    test "with blank name returns error changeset", %{book: book} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "", account_type: "checking"}

      assert {:error, changeset} = CreateAccount.call(scope, book, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with invalid account type returns error changeset", %{book: book} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Test Account", account_type: "invalid_type"}

      assert {:error, changeset} = CreateAccount.call(scope, book, attrs)
      assert %{account_type: ["is invalid"]} = errors_on(changeset)
    end

    test "with owner role (authorized scope) creates an account", %{book: book} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Owner Account", account_type: "savings", description: "My savings account"}

      assert {:ok, %Account{} = account} = CreateAccount.call(scope, book, attrs)
      assert account.name == "Owner Account"
      assert account.account_type == "savings"
      assert account.book_id == book.id
      assert account.description == "My savings account"
      assert is_binary(account.external_id)
      # UUID length
      assert String.length(account.external_id) == 36
    end

    test "with editor role (authorized scope) creates an account", %{book: book} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Editor Account", account_type: "credit_card"}

      assert {:ok, %Account{} = account} = CreateAccount.call(scope, book, attrs)
      assert account.name == "Editor Account"
      assert account.account_type == "credit_card"
      assert account.book_id == book.id
      assert is_binary(account.external_id)
      # UUID length
      assert String.length(account.external_id) == 36
    end

    test "with commenter role (unauthorized scope) returns error", %{book: book} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Commenter Account", account_type: "checking"}

      assert {:error, :unauthorized} = CreateAccount.call(scope, book, attrs)
    end

    test "with no association to book (unauthorized scope) returns error", %{book: book} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Unauthorized Account", account_type: "checking"}

      assert {:error, :unauthorized} = CreateAccount.call(scope, book, attrs)
    end

    test "invokes BroadcastBook when account is created successfully", %{book: book} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      expect(BroadcastBook, :call, fn broadcast_book, {:account_created, broadcast_account} ->
        assert broadcast_book == book
        assert broadcast_account.name == "Broadcast Test Account"
        :ok
      end)

      attrs = %{name: "Broadcast Test Account", account_type: "cash"}

      assert {:ok, %Account{}} = CreateAccount.call(scope, book, attrs)

      verify!()
    end

    test "assigns position 'm' for first account in a book", %{book: book} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "First Account", account_type: "checking"}

      assert {:ok, %Account{} = account} = CreateAccount.call(scope, book, attrs)
      assert account.position == "m"
    end

    test "assigns position before existing accounts", %{book: book} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      # Create first account
      AccountingFactory.insert(:account, book: book, position: "m")

      attrs = %{name: "Second Account", account_type: "savings"}

      assert {:ok, %Account{} = account} = CreateAccount.call(scope, book, attrs)
      assert account.position < "m"
      assert account.position == "g"
    end

    test "handles multiple accounts being added at the top", %{book: book} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      # Create initial accounts
      AccountingFactory.insert(:account, book: book, position: "g")
      AccountingFactory.insert(:account, book: book, position: "m")
      AccountingFactory.insert(:account, book: book, position: "t")

      attrs = %{name: "New Top Account", account_type: "checking"}

      assert {:ok, %Account{} = account} = CreateAccount.call(scope, book, attrs)
      assert account.position < "g"
      assert account.position == "d"
    end

    test "returns error when first account is already at 'a'", %{book: book} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      # Create an account at the boundary
      AccountingFactory.insert(:account, book: book, position: "a")

      attrs = %{name: "Cannot Place At Top", account_type: "checking"}

      assert {:error, :cannot_place_at_top} = CreateAccount.call(scope, book, attrs)
    end
  end
end
