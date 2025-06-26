defmodule PurseCraft.Accounting.Repositories.AccountRepositoryTest do
  use PurseCraft.DataCase, async: true

  alias Ecto.Association.NotLoaded
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.AccountingFactory
  alias PurseCraft.CoreFactory

  setup do
    book = CoreFactory.insert(:book)
    {:ok, book: book}
  end

  describe "create/1" do
    test "with valid attributes creates an account", %{book: book} do
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

    test "with invalid name returns error changeset", %{book: book} do
      attrs = %{
        name: "",
        account_type: "checking",
        book_id: book.id,
        position: "m"
      }

      assert {:error, changeset} = AccountRepository.create(attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with invalid account_type returns error changeset", %{book: book} do
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

    test "validates position format", %{book: book} do
      attrs = %{
        name: "Test Account",
        account_type: "checking",
        book_id: book.id,
        position: "INVALID"
      }

      assert {:error, changeset} = AccountRepository.create(attrs)
      assert %{position: ["must contain only lowercase letters"]} = errors_on(changeset)
    end

    test "enforces book_id + position unique constraint", %{book: book} do
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
    test "returns nil when no accounts exist in book", %{book: book} do
      assert AccountRepository.get_first_position(book.id) == nil
    end

    test "returns position of first account when accounts exist", %{book: book} do
      AccountingFactory.insert(:account, book: book, position: "m")
      AccountingFactory.insert(:account, book: book, position: "g")
      AccountingFactory.insert(:account, book: book, position: "t")

      assert AccountRepository.get_first_position(book.id) == "g"
    end

    test "returns single account position when only one account exists", %{book: book} do
      AccountingFactory.insert(:account, book: book, position: "m")

      assert AccountRepository.get_first_position(book.id) == "m"
    end

    test "ignores accounts from other books", %{book: book} do
      other_book = CoreFactory.insert(:book)
      AccountingFactory.insert(:account, book: book, position: "a")
      AccountingFactory.insert(:account, book: other_book, position: "z")

      assert AccountRepository.get_first_position(book.id) == "a"
      assert AccountRepository.get_first_position(other_book.id) == "z"
    end

    test "handles complex position ordering correctly", %{book: book} do
      AccountingFactory.insert(:account, book: book, position: "m")
      AccountingFactory.insert(:account, book: book, position: "d")
      AccountingFactory.insert(:account, book: book, position: "g")
      AccountingFactory.insert(:account, book: book, position: "b")
      AccountingFactory.insert(:account, book: book, position: "t")

      assert AccountRepository.get_first_position(book.id) == "b"
    end
  end

  describe "get_by_external_id/2" do
    test "returns account when found", %{book: book} do
      account = AccountingFactory.insert(:account, book: book)

      result = AccountRepository.get_by_external_id(account.external_id)

      assert result.id == account.id
      assert result.external_id == account.external_id
    end

    test "returns nil when account not found" do
      result = AccountRepository.get_by_external_id(Ecto.UUID.generate())

      assert result == nil
    end

    test "returns account with preloaded associations", %{book: book} do
      account = AccountingFactory.insert(:account, book: book)

      result = AccountRepository.get_by_external_id(account.external_id, preload: [:book])

      assert result.id == account.id
      assert %NotLoaded{} != result.book
      assert result.book.id == account.book_id
    end

    test "filters closed accounts when active_only is true (default)", %{book: book} do
      closed_account = AccountingFactory.insert(:account, book: book, closed_at: DateTime.utc_now())

      result = AccountRepository.get_by_external_id(closed_account.external_id)

      assert result == nil
    end

    test "includes closed accounts when active_only is false", %{book: book} do
      closed_account = AccountingFactory.insert(:account, book: book, closed_at: DateTime.utc_now())

      result = AccountRepository.get_by_external_id(closed_account.external_id, active_only: false)

      assert result.id == closed_account.id
    end
  end

  describe "list_by_book/2" do
    test "returns all accounts for a book ordered by position", %{book: book} do
      account1 = AccountingFactory.insert(:account, book: book, position: "bbbb")
      account2 = AccountingFactory.insert(:account, book: book, position: "aaaa")
      account3 = AccountingFactory.insert(:account, book: book, position: "cccc")

      result = AccountRepository.list_by_book(book.id)

      assert length(result) == 3
      assert [first, second, third] = result
      assert first.id == account2.id
      assert second.id == account1.id
      assert third.id == account3.id
    end

    test "returns empty list when no accounts exist", %{book: book} do
      result = AccountRepository.list_by_book(book.id)

      assert result == []
    end

    test "returns accounts with preloaded associations", %{book: book} do
      AccountingFactory.insert(:account, book: book, position: "aaaa")

      result = AccountRepository.list_by_book(book.id, preload: [:book])

      assert [account] = result
      assert %NotLoaded{} != account.book
      assert account.book.id == book.id
    end

    test "filters closed accounts when active_only is true (default)", %{book: book} do
      AccountingFactory.insert(:account, book: book, position: "aaaa")
      AccountingFactory.insert(:account, book: book, position: "bbbb", closed_at: DateTime.utc_now())

      result = AccountRepository.list_by_book(book.id)

      assert length(result) == 1
    end

    test "includes closed accounts when active_only is false", %{book: book} do
      active_account = AccountingFactory.insert(:account, book: book, position: "aaaa")
      closed_account = AccountingFactory.insert(:account, book: book, position: "bbbb", closed_at: DateTime.utc_now())

      result = AccountRepository.list_by_book(book.id, active_only: false)

      assert length(result) == 2
      assert [first, second] = result
      assert first.id == active_account.id
      assert second.id == closed_account.id
    end

    test "only returns accounts for specified book", %{book: book} do
      other_book = CoreFactory.insert(:book)
      AccountingFactory.insert(:account, book: book, position: "aaaa")
      AccountingFactory.insert(:account, book: other_book, position: "aaaa")

      result = AccountRepository.list_by_book(book.id)

      assert length(result) == 1
      assert [account] = result
      assert account.book_id == book.id
    end

    test "handles multiple options together", %{book: book} do
      active_account = AccountingFactory.insert(:account, book: book, position: "aaaa")
      AccountingFactory.insert(:account, book: book, position: "bbbb", closed_at: DateTime.utc_now())

      result = AccountRepository.list_by_book(book.id, preload: [:book], active_only: true)

      assert length(result) == 1
      assert [account] = result
      assert account.id == active_account.id
      assert %NotLoaded{} != account.book
    end

    test "handles book with no accounts returns empty list" do
      non_existent_book_id = 999_999

      result = AccountRepository.list_by_book(non_existent_book_id)

      assert result == []
    end
  end

  describe "update/2" do
    test "with valid attributes updates an account", %{book: book} do
      account = AccountingFactory.insert(:account, book: book, name: "Old Name", description: "Old Description")
      attrs = %{name: "New Name", description: "New Description"}

      assert {:ok, %Account{} = updated_account} = AccountRepository.update(account, attrs)
      assert updated_account.id == account.id
      assert updated_account.name == "New Name"
      assert updated_account.description == "New Description"
      assert updated_account.account_type == account.account_type
      assert updated_account.position == account.position
      assert updated_account.book_id == account.book_id
    end

    test "with invalid name returns error changeset", %{book: book} do
      account = AccountingFactory.insert(:account, book: book)
      attrs = %{name: ""}

      assert {:error, changeset} = AccountRepository.update(account, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "with empty description updates successfully", %{book: book} do
      account = AccountingFactory.insert(:account, book: book, description: "Old Description")
      attrs = %{description: ""}

      assert {:ok, updated_account} = AccountRepository.update(account, attrs)
      assert updated_account.description == nil
    end

    test "with nil attributes handles gracefully", %{book: book} do
      account = AccountingFactory.insert(:account, book: book, name: "Original Name")
      attrs = %{name: nil}

      assert {:error, changeset} = AccountRepository.update(account, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "ignores account_type changes", %{book: book} do
      account = AccountingFactory.insert(:account, book: book, account_type: "checking")
      attrs = %{account_type: "savings", name: "Updated Name"}

      assert {:ok, updated_account} = AccountRepository.update(account, attrs)
      assert updated_account.account_type == "checking"
      assert updated_account.name == "Updated Name"
    end

    test "ignores position changes", %{book: book} do
      account = AccountingFactory.insert(:account, book: book, position: "m")
      attrs = %{position: "z", name: "Updated Name"}

      assert {:ok, updated_account} = AccountRepository.update(account, attrs)
      assert updated_account.position == "m"
      assert updated_account.name == "Updated Name"
    end

    test "ignores book_id changes", %{book: book} do
      other_book = CoreFactory.insert(:book)
      account = AccountingFactory.insert(:account, book: book)
      attrs = %{book_id: other_book.id, name: "Updated Name"}

      assert {:ok, updated_account} = AccountRepository.update(account, attrs)
      assert updated_account.book_id == book.id
      assert updated_account.name == "Updated Name"
    end

    test "ignores external_id changes", %{book: book} do
      account = AccountingFactory.insert(:account, book: book)
      original_external_id = account.external_id
      attrs = %{external_id: Ecto.UUID.generate(), name: "Updated Name"}

      assert {:ok, updated_account} = AccountRepository.update(account, attrs)
      assert updated_account.external_id == original_external_id
      assert updated_account.name == "Updated Name"
    end
  end

  describe "delete/1" do
    test "with valid account deletes successfully", %{book: book} do
      account = AccountingFactory.insert(:account, book: book)

      assert {:ok, deleted_account} = AccountRepository.delete(account)
      assert deleted_account.id == account.id

      assert AccountRepository.get_by_external_id(account.external_id, active_only: false) == nil
    end

    test "with already deleted account returns error", %{book: book} do
      account = AccountingFactory.insert(:account, book: book)

      assert {:ok, _deleted_account} = AccountRepository.delete(account)

      assert {:error, changeset} = AccountRepository.delete(account)
      assert changeset.errors[:id] == {"is stale", [stale: true]}
    end
  end
end
