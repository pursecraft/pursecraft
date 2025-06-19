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

  describe "get_by_external_id/2,3" do
    test "returns account when found with valid external_id" do
      book = AccountingFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book)

      result = AccountRepository.get_by_external_id(book.id, account.external_id)

      assert result.id == account.id
      assert result.name == account.name
      assert result.external_id == account.external_id
    end

    test "returns nil when account not found" do
      book = AccountingFactory.insert(:book)

      result = AccountRepository.get_by_external_id(book.id, Ecto.UUID.generate())

      assert is_nil(result)
    end

    test "returns nil when account belongs to different book" do
      book1 = AccountingFactory.insert(:book)
      book2 = AccountingFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book1)

      result = AccountRepository.get_by_external_id(book2.id, account.external_id)

      assert is_nil(result)
    end

    test "filters out closed account by default" do
      book = AccountingFactory.insert(:book)
      closed_account = AccountingFactory.insert(:account, book: book, closed_at: DateTime.utc_now())

      result = AccountRepository.get_by_external_id(book.id, closed_account.external_id)

      assert is_nil(result)
    end

    test "returns closed account with active_only: false" do
      book = AccountingFactory.insert(:book)
      closed_account = AccountingFactory.insert(:account, book: book, closed_at: DateTime.utc_now())

      result = AccountRepository.get_by_external_id(book.id, closed_account.external_id, active_only: false)

      assert result.id == closed_account.id
      assert not is_nil(result.closed_at)
    end

    test "returns active account by default" do
      book = AccountingFactory.insert(:book)
      active_account = AccountingFactory.insert(:account, book: book)

      result = AccountRepository.get_by_external_id(book.id, active_account.external_id)

      assert result.id == active_account.id
      assert is_nil(result.closed_at)
    end

    test "returns account without preloads by default" do
      book = AccountingFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book)

      result = AccountRepository.get_by_external_id(book.id, account.external_id)

      assert %Ecto.Association.NotLoaded{} = result.book
    end

    test "preloads associations when specified" do
      book = AccountingFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book)

      result = AccountRepository.get_by_external_id(book.id, account.external_id, preload: [:book])

      assert result.book.id == book.id
      assert result.book.name == book.name
    end

    test "handles empty preload list" do
      book = AccountingFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book)

      result = AccountRepository.get_by_external_id(book.id, account.external_id, preload: [])

      assert %Ecto.Association.NotLoaded{} = result.book
    end

    test "works with both active_only and preload options" do
      book = AccountingFactory.insert(:book)
      active_account = AccountingFactory.insert(:account, book: book)

      result = AccountRepository.get_by_external_id(book.id, active_account.external_id, active_only: true, preload: [:book])

      assert result.id == active_account.id
      assert is_nil(result.closed_at)
      assert result.book.id == book.id
    end

    test "returns closed account with active_only: false and preload options" do
      book = AccountingFactory.insert(:book)
      closed_account = AccountingFactory.insert(:account, book: book, closed_at: DateTime.utc_now())

      result = AccountRepository.get_by_external_id(book.id, closed_account.external_id, active_only: false, preload: [:book])

      assert result.id == closed_account.id
      assert not is_nil(result.closed_at)
      assert result.book.id == book.id
    end
  end
end