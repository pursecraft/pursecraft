defmodule PurseCraft.Accounting.Repositories.AccountRepositoryTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.AccountingFactory

  describe "create/1" do
    test "creates an account with valid attributes" do
      book = AccountingFactory.insert(:book)

      attrs = %{
        name: "Test Account",
        account_type: "checking",
        description: "My test account",
        book_id: book.id,
        position: "m"
      }

      assert {:ok, %Account{} = account} = AccountRepository.create(attrs)
      assert account.name == "Test Account"
      assert account.account_type == "checking"
      assert account.description == "My test account"
      assert account.book_id == book.id
      assert account.position == "m"
      assert is_binary(account.external_id)
      assert String.length(account.external_id) == 36
    end

    test "creates an account without optional description" do
      book = AccountingFactory.insert(:book)

      attrs = %{
        name: "Simple Account",
        account_type: "savings",
        book_id: book.id,
        position: "m"
      }

      assert {:ok, %Account{} = account} = AccountRepository.create(attrs)
      assert account.name == "Simple Account"
      assert account.account_type == "savings"
      assert is_nil(account.description)
      assert account.book_id == book.id
      assert account.position == "m"
    end

    test "returns error changeset with invalid attributes" do
      attrs = %{
        name: "",
        account_type: "checking",
        book_id: 1,
        position: "m"
      }

      assert {:error, changeset} = AccountRepository.create(attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset with invalid account type" do
      book = AccountingFactory.insert(:book)

      attrs = %{
        name: "Test Account",
        account_type: "invalid_type",
        book_id: book.id,
        position: "m"
      }

      assert {:error, changeset} = AccountRepository.create(attrs)
      assert %{account_type: ["is invalid"]} = errors_on(changeset)
    end

    test "returns error changeset with missing required fields" do
      attrs = %{
        name: "Test Account"
      }

      assert {:error, changeset} = AccountRepository.create(attrs)
      errors = errors_on(changeset)
      assert %{account_type: ["can't be blank"]} = errors
      assert %{book_id: ["can't be blank"]} = errors
      assert %{position: ["can't be blank"]} = errors
    end

    test "returns error changeset with invalid position format" do
      book = AccountingFactory.insert(:book)

      attrs = %{
        name: "Test Account",
        account_type: "checking",
        book_id: book.id,
        position: "INVALID123"
      }

      assert {:error, changeset} = AccountRepository.create(attrs)
      assert %{position: ["must contain only lowercase letters"]} = errors_on(changeset)
    end

    test "returns error changeset with non-existent book_id" do
      attrs = %{
        name: "Test Account",
        account_type: "checking",
        book_id: 999999,
        position: "m"
      }

      assert {:error, changeset} = AccountRepository.create(attrs)
      assert %{book_id: ["does not exist"]} = errors_on(changeset)
    end
  end

  describe "get_first_position/1" do
    test "returns the position of the first account when accounts exist" do
      book = AccountingFactory.insert(:book)
      AccountingFactory.insert(:account, book: book, position: "m")
      AccountingFactory.insert(:account, book: book, position: "g")
      AccountingFactory.insert(:account, book: book, position: "t")

      result = AccountRepository.get_first_position(book.id)

      assert result == "g"
    end

    test "returns nil when no accounts exist for the book" do
      book = AccountingFactory.insert(:book)

      result = AccountRepository.get_first_position(book.id)

      assert is_nil(result)
    end

    test "returns first position when only one account exists" do
      book = AccountingFactory.insert(:book)
      AccountingFactory.insert(:account, book: book, position: "m")

      result = AccountRepository.get_first_position(book.id)

      assert result == "m"
    end

    test "ignores accounts from other books" do
      book1 = AccountingFactory.insert(:book)
      book2 = AccountingFactory.insert(:book)
      
      AccountingFactory.insert(:account, book: book1, position: "m")
      AccountingFactory.insert(:account, book: book2, position: "a")

      result = AccountRepository.get_first_position(book1.id)

      assert result == "m"
    end
  end
end