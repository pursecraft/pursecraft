defmodule PurseCraft.Accounting.Repositories.AccountRepositoryTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.AccountingFactory
  alias PurseCraft.CoreFactory

  describe "create/1" do
    test "with valid attributes creates an account" do
      book = CoreFactory.insert(:book)

      attrs = %{
        name: "Test Account",
        account_type: "checking",
        description: "Test Description",
        book_id: book.id,
        position: "m"
      }

      assert {:ok, %Account{} = account} = AccountRepository.create(attrs)
      assert account.name == "Test Account"
      assert account.account_type == "checking"
      assert account.description == "Test Description"
      assert account.book_id == book.id
      assert account.position == "m"
      assert is_binary(account.external_id)
    end

    test "with invalid name returns error changeset" do
      book = CoreFactory.insert(:book)

      attrs = %{
        name: "",
        account_type: "checking",
        book_id: book.id,
        position: "m"
      }

      assert {:error, changeset} = AccountRepository.create(attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with invalid account_type returns error changeset" do
      book = CoreFactory.insert(:book)

      attrs = %{
        name: "Test Account",
        account_type: "invalid_type",
        book_id: book.id,
        position: "m"
      }

      assert {:error, changeset} = AccountRepository.create(attrs)
      assert %{account_type: ["is invalid"]} = errors_on(changeset)
    end

    test "with missing required fields returns error changeset" do
      attrs = %{name: "Test Account"}

      assert {:error, changeset} = AccountRepository.create(attrs)
      assert %{book_id: ["can't be blank"], position: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates position format" do
      book = CoreFactory.insert(:book)

      attrs = %{
        name: "Test Account",
        account_type: "checking",
        book_id: book.id,
        position: "INVALID"
      }

      assert {:error, changeset} = AccountRepository.create(attrs)
      assert %{position: ["must contain only lowercase letters"]} = errors_on(changeset)
    end

    test "enforces book_id + position unique constraint" do
      book = CoreFactory.insert(:book)
      AccountingFactory.insert(:account, book: book, position: "m")

      attrs = %{
        name: "Duplicate Position Account",
        account_type: "checking",
        book_id: book.id,
        position: "m"
      }

      assert {:error, changeset} = AccountRepository.create(attrs)
      assert %{position: ["has already been taken"]} = errors_on(changeset)
    end

    test "allows same position in different books" do
      book1 = CoreFactory.insert(:book)
      book2 = CoreFactory.insert(:book)
      AccountingFactory.insert(:account, book: book1, position: "m")

      attrs = %{
        name: "Same Position Different Book",
        account_type: "checking",
        book_id: book2.id,
        position: "m"
      }

      assert {:ok, %Account{}} = AccountRepository.create(attrs)
    end
  end

  describe "get_first_position/1" do
    test "returns nil when no accounts exist in book" do
      book = CoreFactory.insert(:book)

      assert AccountRepository.get_first_position(book.id) == nil
    end

    test "returns position of first account when accounts exist" do
      book = CoreFactory.insert(:book)
      AccountingFactory.insert(:account, book: book, position: "m")
      AccountingFactory.insert(:account, book: book, position: "g")
      AccountingFactory.insert(:account, book: book, position: "t")

      assert AccountRepository.get_first_position(book.id) == "g"
    end

    test "returns single account position when only one account exists" do
      book = CoreFactory.insert(:book)
      AccountingFactory.insert(:account, book: book, position: "m")

      assert AccountRepository.get_first_position(book.id) == "m"
    end

    test "ignores accounts from other books" do
      book1 = CoreFactory.insert(:book)
      book2 = CoreFactory.insert(:book)
      AccountingFactory.insert(:account, book: book1, position: "a")
      AccountingFactory.insert(:account, book: book2, position: "z")

      assert AccountRepository.get_first_position(book1.id) == "a"
      assert AccountRepository.get_first_position(book2.id) == "z"
    end

    test "handles complex position ordering correctly" do
      book = CoreFactory.insert(:book)
      AccountingFactory.insert(:account, book: book, position: "m")
      AccountingFactory.insert(:account, book: book, position: "d")
      AccountingFactory.insert(:account, book: book, position: "g")
      AccountingFactory.insert(:account, book: book, position: "b")
      AccountingFactory.insert(:account, book: book, position: "t")

      assert AccountRepository.get_first_position(book.id) == "b"
    end
  end
end
