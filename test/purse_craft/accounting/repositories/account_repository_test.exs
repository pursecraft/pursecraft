defmodule PurseCraft.Accounting.Repositories.AccountRepositoryTest do
  use PurseCraft.DataCase, async: true

  alias Ecto.Association.NotLoaded
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.AccountingFactory
  alias PurseCraft.IdentityFactory

  describe "create/1" do
    test "creates an account with valid attributes" do
      book = IdentityFactory.insert(:book)

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
      book = IdentityFactory.insert(:book)

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
      book = IdentityFactory.insert(:book)

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
      book = IdentityFactory.insert(:book)

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
        book_id: 999_999,
        position: "m"
      }

      assert {:error, changeset} = AccountRepository.create(attrs)
      assert %{book_id: ["does not exist"]} = errors_on(changeset)
    end
  end

  describe "get_first_position/1" do
    test "returns the position of the first account when accounts exist" do
      book = IdentityFactory.insert(:book)
      AccountingFactory.insert(:account, book: book, position: "m")
      AccountingFactory.insert(:account, book: book, position: "g")
      AccountingFactory.insert(:account, book: book, position: "t")

      result = AccountRepository.get_first_position(book.id)

      assert result == "g"
    end

    test "returns nil when no accounts exist for the book" do
      book = IdentityFactory.insert(:book)

      result = AccountRepository.get_first_position(book.id)

      assert is_nil(result)
    end

    test "returns first position when only one account exists" do
      book = IdentityFactory.insert(:book)
      AccountingFactory.insert(:account, book: book, position: "m")

      result = AccountRepository.get_first_position(book.id)

      assert result == "m"
    end

    test "ignores accounts from other books" do
      book1 = IdentityFactory.insert(:book)
      book2 = IdentityFactory.insert(:book)

      AccountingFactory.insert(:account, book: book1, position: "m")
      AccountingFactory.insert(:account, book: book2, position: "a")

      result = AccountRepository.get_first_position(book1.id)

      assert result == "m"
    end
  end

  describe "get_by_external_id/2,3" do
    test "returns account when found with valid external_id" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book)

      result = AccountRepository.get_by_external_id(book.id, account.external_id)

      assert result.id == account.id
      assert result.name == account.name
      assert result.external_id == account.external_id
    end

    test "returns nil when account not found" do
      book = IdentityFactory.insert(:book)

      result = AccountRepository.get_by_external_id(book.id, Ecto.UUID.generate())

      assert is_nil(result)
    end

    test "returns nil when account belongs to different book" do
      book1 = IdentityFactory.insert(:book)
      book2 = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book1)

      result = AccountRepository.get_by_external_id(book2.id, account.external_id)

      assert is_nil(result)
    end

    test "filters out closed account by default" do
      book = IdentityFactory.insert(:book)
      closed_account = AccountingFactory.insert(:account, book: book, closed_at: DateTime.utc_now())

      result = AccountRepository.get_by_external_id(book.id, closed_account.external_id)

      assert is_nil(result)
    end

    test "returns closed account with active_only: false" do
      book = IdentityFactory.insert(:book)
      closed_account = AccountingFactory.insert(:account, book: book, closed_at: DateTime.utc_now())

      result = AccountRepository.get_by_external_id(book.id, closed_account.external_id, active_only: false)

      assert result.id == closed_account.id
      assert not is_nil(result.closed_at)
    end

    test "returns active account by default" do
      book = IdentityFactory.insert(:book)
      active_account = AccountingFactory.insert(:account, book: book)

      result = AccountRepository.get_by_external_id(book.id, active_account.external_id)

      assert result.id == active_account.id
      assert is_nil(result.closed_at)
    end

    test "returns account without preloads by default" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book)

      result = AccountRepository.get_by_external_id(book.id, account.external_id)

      assert %NotLoaded{} = result.book
    end

    test "preloads associations when specified" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book)

      result = AccountRepository.get_by_external_id(book.id, account.external_id, preload: [:book])

      assert result.book.id == book.id
      assert result.book.name == book.name
    end

    test "handles empty preload list" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book)

      result = AccountRepository.get_by_external_id(book.id, account.external_id, preload: [])

      assert %NotLoaded{} = result.book
    end

    test "works with both active_only and preload options" do
      book = IdentityFactory.insert(:book)
      active_account = AccountingFactory.insert(:account, book: book)

      result =
        AccountRepository.get_by_external_id(book.id, active_account.external_id, active_only: true, preload: [:book])

      assert result.id == active_account.id
      assert is_nil(result.closed_at)
      assert result.book.id == book.id
    end

    test "returns closed account with active_only: false and preload options" do
      book = IdentityFactory.insert(:book)
      closed_account = AccountingFactory.insert(:account, book: book, closed_at: DateTime.utc_now())

      result =
        AccountRepository.get_by_external_id(book.id, closed_account.external_id, active_only: false, preload: [:book])

      assert result.id == closed_account.id
      assert not is_nil(result.closed_at)
      assert result.book.id == book.id
    end
  end

  describe "list_by_book/2" do
    test "returns accounts for specified book ordered by position" do
      book = IdentityFactory.insert(:book)
      account1 = AccountingFactory.insert(:account, book: book, position: "m")
      account2 = AccountingFactory.insert(:account, book: book, position: "g")
      account3 = AccountingFactory.insert(:account, book: book, position: "t")

      result = AccountRepository.list_by_book(book.id)

      assert length(result) == 3
      assert Enum.map(result, & &1.id) == [account2.id, account1.id, account3.id]
    end

    test "returns empty list when no accounts exist for book" do
      book = IdentityFactory.insert(:book)

      result = AccountRepository.list_by_book(book.id)

      assert result == []
    end

    test "returns only accounts for specified book" do
      book1 = IdentityFactory.insert(:book)
      book2 = IdentityFactory.insert(:book)
      account1 = AccountingFactory.insert(:account, book: book1, position: "m")
      AccountingFactory.insert(:account, book: book2, position: "g")

      result = AccountRepository.list_by_book(book1.id)

      assert length(result) == 1
      assert hd(result).id == account1.id
    end

    test "filters out closed accounts by default" do
      book = IdentityFactory.insert(:book)
      active_account = AccountingFactory.insert(:account, book: book, position: "m")
      AccountingFactory.insert(:account, book: book, position: "g", closed_at: DateTime.utc_now())

      result = AccountRepository.list_by_book(book.id)

      assert length(result) == 1
      assert hd(result).id == active_account.id
    end

    test "includes closed accounts with active_only: false" do
      book = IdentityFactory.insert(:book)
      active_account = AccountingFactory.insert(:account, book: book, position: "m")
      closed_account = AccountingFactory.insert(:account, book: book, position: "g", closed_at: DateTime.utc_now())

      result = AccountRepository.list_by_book(book.id, active_only: false)

      assert length(result) == 2
      account_ids = Enum.map(result, & &1.id)
      assert closed_account.id in account_ids
      assert active_account.id in account_ids
    end

    test "returns accounts without preloads by default" do
      book = IdentityFactory.insert(:book)
      AccountingFactory.insert(:account, book: book, position: "m")

      result = AccountRepository.list_by_book(book.id)

      account = hd(result)
      assert %NotLoaded{} = account.book
    end

    test "preloads associations when specified" do
      book = IdentityFactory.insert(:book)
      AccountingFactory.insert(:account, book: book, position: "m")

      result = AccountRepository.list_by_book(book.id, preload: [:book])

      account = hd(result)
      assert account.book.id == book.id
      assert account.book.name == book.name
    end

    test "handles empty preload list" do
      book = IdentityFactory.insert(:book)
      AccountingFactory.insert(:account, book: book, position: "m")

      result = AccountRepository.list_by_book(book.id, preload: [])

      account = hd(result)
      assert %NotLoaded{} = account.book
    end

    test "works with both active_only and preload options" do
      book = IdentityFactory.insert(:book)
      active_account = AccountingFactory.insert(:account, book: book, position: "m")
      AccountingFactory.insert(:account, book: book, position: "g", closed_at: DateTime.utc_now())

      result = AccountRepository.list_by_book(book.id, active_only: true, preload: [:book])

      assert length(result) == 1
      account = hd(result)
      assert account.id == active_account.id
      assert is_nil(account.closed_at)
      assert account.book.id == book.id
    end

    test "returns closed accounts with active_only: false and preload options" do
      book = IdentityFactory.insert(:book)
      active_account = AccountingFactory.insert(:account, book: book, position: "m")
      closed_account = AccountingFactory.insert(:account, book: book, position: "g", closed_at: DateTime.utc_now())

      result = AccountRepository.list_by_book(book.id, active_only: false, preload: [:book])

      assert length(result) == 2
      account_ids = Enum.map(result, & &1.id)
      assert closed_account.id in account_ids
      assert active_account.id in account_ids

      Enum.each(result, fn account ->
        assert account.book.id == book.id
      end)
    end
  end

  describe "update/2" do
    test "updates an account with valid attributes" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book, name: "Original Name", description: "Original Description")

      attrs = %{name: "Updated Name", description: "Updated Description"}

      assert {:ok, %Account{} = updated_account} = AccountRepository.update(account, attrs)
      assert updated_account.id == account.id
      assert updated_account.name == "Updated Name"
      assert updated_account.description == "Updated Description"
      assert updated_account.account_type == account.account_type
      assert updated_account.book_id == account.book_id
      assert updated_account.position == account.position
    end

    test "updates account name only" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book, name: "Old Name", description: "Keep Description")

      attrs = %{name: "New Name"}

      assert {:ok, %Account{} = updated_account} = AccountRepository.update(account, attrs)
      assert updated_account.name == "New Name"
      assert updated_account.description == "Keep Description"
    end

    test "updates account description only" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book, name: "Keep Name", description: "Old Description")

      attrs = %{description: "New Description"}

      assert {:ok, %Account{} = updated_account} = AccountRepository.update(account, attrs)
      assert updated_account.name == "Keep Name"
      assert updated_account.description == "New Description"
    end

    test "clears description when set to nil" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book, description: "Remove This")

      attrs = %{description: nil}

      assert {:ok, %Account{} = updated_account} = AccountRepository.update(account, attrs)
      assert is_nil(updated_account.description)
    end

    test "returns error changeset with blank name" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book)

      attrs = %{name: ""}

      assert {:error, changeset} = AccountRepository.update(account, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset with nil name" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book)

      attrs = %{name: nil}

      assert {:error, changeset} = AccountRepository.update(account, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "ignores account_type changes in attributes" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book, account_type: "checking")

      attrs = %{name: "Updated Name", account_type: "savings"}

      assert {:ok, %Account{} = updated_account} = AccountRepository.update(account, attrs)
      assert updated_account.name == "Updated Name"
      assert updated_account.account_type == "checking"
    end

    test "ignores position changes in attributes" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book, position: "m")

      attrs = %{name: "Updated Name", position: "z"}

      assert {:ok, %Account{} = updated_account} = AccountRepository.update(account, attrs)
      assert updated_account.name == "Updated Name"
      assert updated_account.position == "m"
    end

    test "ignores book_id changes in attributes" do
      book1 = IdentityFactory.insert(:book)
      book2 = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book1)

      attrs = %{name: "Updated Name", book_id: book2.id}

      assert {:ok, %Account{} = updated_account} = AccountRepository.update(account, attrs)
      assert updated_account.name == "Updated Name"
      assert updated_account.book_id == book1.id
    end

    test "ignores external_id changes in attributes" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book)
      original_external_id = account.external_id

      attrs = %{name: "Updated Name", external_id: Ecto.UUID.generate()}

      assert {:ok, %Account{} = updated_account} = AccountRepository.update(account, attrs)
      assert updated_account.name == "Updated Name"
      assert updated_account.external_id == original_external_id
    end

    test "handles string keys in attributes" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book)

      attrs = %{"name" => "String Key Name", "description" => "String Key Description"}

      assert {:ok, %Account{} = updated_account} = AccountRepository.update(account, attrs)
      assert updated_account.name == "String Key Name"
      assert updated_account.description == "String Key Description"
    end

    test "updates encrypted fields and hash fields correctly" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book, name: "Original")

      attrs = %{name: "Encrypted Update"}

      assert {:ok, %Account{} = updated_account} = AccountRepository.update(account, attrs)
      assert updated_account.name == "Encrypted Update"
      assert updated_account.name_hash != account.name_hash
      refute is_nil(updated_account.name_hash)
    end
  end

  describe "close/1" do
    test "closes an account successfully" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book)

      assert {:ok, %Account{} = closed_account} = AccountRepository.close(account)
      assert closed_account.id == account.id
      assert closed_account.external_id == account.external_id
      assert not is_nil(closed_account.closed_at)

      persisted_account = Repo.get(Account, account.id)
      assert persisted_account
      assert not is_nil(persisted_account.closed_at)
    end
  end

  describe "delete/1" do
    test "deletes an account successfully" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book)

      assert {:ok, %Account{} = deleted_account} = AccountRepository.delete(account)
      assert deleted_account.id == account.id
      assert deleted_account.external_id == account.external_id

      refute Repo.get(Account, account.id)
    end
  end

  describe "update_position/2" do
    test "updates account position successfully" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book, position: "m")

      assert {:ok, %Account{} = updated_account} = AccountRepository.update_position(account, "z")
      assert updated_account.id == account.id
      assert updated_account.position == "z"
      assert updated_account.external_id == account.external_id
    end

    test "returns error changeset with invalid position format" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book, position: "m")

      assert {:error, changeset} = AccountRepository.update_position(account, "INVALID123")
      assert %{position: ["must contain only lowercase letters"]} = errors_on(changeset)
    end

    test "persists position change to database" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book, position: "m")

      assert {:ok, _updated_account} = AccountRepository.update_position(account, "b")

      persisted_account = Repo.get(Account, account.id)
      assert persisted_account.position == "b"
    end
  end

  describe "list_by_external_ids/2" do
    test "returns accounts matching given external IDs" do
      book = IdentityFactory.insert(:book)
      account1 = AccountingFactory.insert(:account, book: book)
      account2 = AccountingFactory.insert(:account, book: book)
      account3 = AccountingFactory.insert(:account, book: book)

      external_ids = [account1.external_id, account3.external_id]
      result = AccountRepository.list_by_external_ids(external_ids)

      assert length(result) == 2
      returned_ids = Enum.map(result, & &1.external_id)
      assert account1.external_id in returned_ids
      assert account3.external_id in returned_ids
      refute account2.external_id in returned_ids
    end

    test "returns empty list when no matching external IDs" do
      book = IdentityFactory.insert(:book)
      AccountingFactory.insert(:account, book: book)

      result = AccountRepository.list_by_external_ids([Ecto.UUID.generate(), Ecto.UUID.generate()])

      assert result == []
    end

    test "returns accounts without preloads by default" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book)

      result = AccountRepository.list_by_external_ids([account.external_id])

      returned_account = hd(result)
      assert %NotLoaded{} = returned_account.book
    end

    test "preloads associations when specified" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book)

      result = AccountRepository.list_by_external_ids([account.external_id], preload: [:book])

      returned_account = hd(result)
      assert returned_account.book.id == book.id
      assert returned_account.book.name == book.name
    end

    test "handles empty external_ids list" do
      book = IdentityFactory.insert(:book)
      AccountingFactory.insert(:account, book: book)

      result = AccountRepository.list_by_external_ids([])

      assert result == []
    end

    test "returns accounts from different books" do
      book1 = IdentityFactory.insert(:book)
      book2 = IdentityFactory.insert(:book)
      account1 = AccountingFactory.insert(:account, book: book1)
      account2 = AccountingFactory.insert(:account, book: book2)

      external_ids = [account1.external_id, account2.external_id]
      result = AccountRepository.list_by_external_ids(external_ids)

      assert length(result) == 2
      returned_ids = Enum.map(result, & &1.external_id)
      assert account1.external_id in returned_ids
      assert account2.external_id in returned_ids
    end

    test "handles duplicate external IDs in input" do
      book = IdentityFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book)

      external_ids = [account.external_id, account.external_id]
      result = AccountRepository.list_by_external_ids(external_ids)

      assert length(result) == 1
      assert hd(result).external_id == account.external_id
    end
  end
end
