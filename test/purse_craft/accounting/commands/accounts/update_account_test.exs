defmodule PurseCraft.Accounting.Commands.Accounts.UpdateAccountTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Accounting.Commands.Accounts.UpdateAccount
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.AccountingFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastBook

  setup do
    book = AccountingFactory.insert(:book)
    account = AccountingFactory.insert(:account, book: book)

    %{
      book: book,
      account: account
    }
  end

  describe "call/4" do
    test "with owner role (authorized scope) updates an account", %{book: book, account: account} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{"name" => "Owner Updated Account", "description" => "Updated by owner"}

      assert {:ok, %Account{} = updated_account} = UpdateAccount.call(scope, book, account.external_id, attrs)
      assert updated_account.name == "Owner Updated Account"
      assert updated_account.description == "Updated by owner"
      assert updated_account.external_id == account.external_id
    end

    test "with editor role (authorized scope) updates an account", %{book: book, account: account} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{"name" => "Editor Updated Account"}

      assert {:ok, %Account{} = updated_account} = UpdateAccount.call(scope, book, account.external_id, attrs)
      assert updated_account.name == "Editor Updated Account"
      assert updated_account.external_id == account.external_id
    end

    test "with commenter role (unauthorized scope) returns error", %{book: book, account: account} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{"name" => "Commenter Updated Account"}

      assert {:error, :unauthorized} = UpdateAccount.call(scope, book, account.external_id, attrs)
    end

    test "with no association to book (unauthorized scope) returns error", %{book: book, account: account} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{"name" => "Unauthorized Updated Account"}

      assert {:error, :unauthorized} = UpdateAccount.call(scope, book, account.external_id, attrs)
    end

    test "with non-existent account returns error", %{book: book} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{"name" => "Non-existent Account"}

      assert {:error, :not_found} = UpdateAccount.call(scope, book, Ecto.UUID.generate(), attrs)
    end

    test "with account_type change attempt ignores the change", %{book: book, account: account} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      original_account_type = account.account_type
      attrs = %{"name" => "Updated Name", "account_type" => "savings"}

      assert {:ok, %Account{} = updated_account} = UpdateAccount.call(scope, book, account.external_id, attrs)
      assert updated_account.name == "Updated Name"
      assert updated_account.account_type == original_account_type
    end

    test "invokes BroadcastBook when account is updated successfully", %{book: book, account: account} do
      user = IdentityFactory.insert(:user)
      AccountingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      expect(BroadcastBook, :call, fn broadcast_book, {:account_updated, broadcast_account} ->
        assert broadcast_book == book
        assert broadcast_account.name == "Broadcast Test Update"
        :ok
      end)

      attrs = %{"name" => "Broadcast Test Update"}

      assert {:ok, %Account{}} = UpdateAccount.call(scope, book, account.external_id, attrs)

      verify!()
    end
  end
end
