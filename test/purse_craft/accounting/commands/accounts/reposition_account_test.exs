defmodule PurseCraft.Accounting.Commands.Accounts.RepositionAccountTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Accounting.Commands.Accounts.RepositionAccount
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.AccountingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastBook

  setup do
    book = CoreFactory.insert(:book)

    acc1 = AccountingFactory.insert(:account, book: book, position: "g")
    acc2 = AccountingFactory.insert(:account, book: book, position: "m")
    acc3 = AccountingFactory.insert(:account, book: book, position: "t")

    %{
      book: book,
      acc1: acc1,
      acc2: acc2,
      acc3: acc3
    }
  end

  describe "call/4" do
    test "successfully repositions account between two others", %{book: book, acc1: acc1, acc2: acc2, acc3: acc3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, updated} = RepositionAccount.call(scope, acc3.external_id, acc1.external_id, acc2.external_id)

      assert updated.id == acc3.id
      assert updated.position > acc1.position
      assert updated.position < acc2.position
    end

    test "repositions account to the beginning when prev_account_id is nil", %{book: book, acc1: acc1, acc3: acc3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, updated} = RepositionAccount.call(scope, acc3.external_id, nil, acc1.external_id)

      assert updated.id == acc3.id
      assert updated.position < acc1.position
    end

    test "repositions account to the end when next_account_id is nil", %{book: book, acc1: acc1, acc3: acc3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, updated} = RepositionAccount.call(scope, acc1.external_id, acc3.external_id, nil)

      assert updated.id == acc1.id
      assert updated.position > acc3.position
    end

    test "returns not_found when account doesn't exist", %{book: book, acc1: acc1, acc2: acc2} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :not_found} =
               RepositionAccount.call(scope, Ecto.UUID.generate(), acc1.external_id, acc2.external_id)
    end

    test "returns not_found when prev_account doesn't exist", %{book: book, acc1: acc1, acc2: acc2} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :not_found} =
               RepositionAccount.call(scope, acc1.external_id, Ecto.UUID.generate(), acc2.external_id)
    end

    test "returns not_found when next_account doesn't exist", %{book: book, acc1: acc1, acc2: acc2} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :not_found} =
               RepositionAccount.call(scope, acc1.external_id, acc2.external_id, Ecto.UUID.generate())
    end

    test "returns not_found when prev_account is from different book", %{book: book, acc1: acc1, acc2: acc2} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      other_book = CoreFactory.insert(:book)
      other_acc = AccountingFactory.insert(:account, book: other_book, position: "a")

      assert {:error, :not_found} =
               RepositionAccount.call(scope, acc1.external_id, other_acc.external_id, acc2.external_id)
    end

    test "returns unauthorized when user lacks permission", %{book: book, acc1: acc1, acc2: acc2, acc3: acc3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} =
               RepositionAccount.call(scope, acc3.external_id, acc1.external_id, acc2.external_id)
    end

    test "returns error when fractional indexing fails", %{book: book} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      acc1 = AccountingFactory.insert(:account, book: book, position: "z")
      acc2 = AccountingFactory.insert(:account, book: book, position: "a")
      acc3 = AccountingFactory.insert(:account, book: book, position: "n")

      assert {:error, :prev_must_be_less_than_next} =
               RepositionAccount.call(scope, acc3.external_id, acc1.external_id, acc2.external_id)
    end

    test "broadcasts account_repositioned event on success", %{book: book, acc1: acc1, acc2: acc2, acc3: acc3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      expect(BroadcastBook, :call, fn received_book, {:account_repositioned, received_account} ->
        assert received_book.id == book.id
        assert received_account.id == acc3.id
        :ok
      end)

      assert {:ok, _updated} = RepositionAccount.call(scope, acc3.external_id, acc1.external_id, acc2.external_id)

      verify!()
    end

    test "handles unique constraint violation with retry", %{book: book, acc1: acc1, acc2: acc2, acc3: acc3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, updated} = RepositionAccount.call(scope, acc3.external_id, acc1.external_id, acc2.external_id)

      assert updated.id == acc3.id
      assert updated.position > acc1.position
      assert updated.position < acc2.position
    end

    test "returns error after max retries", %{book: book, acc1: acc1, acc2: acc2, acc3: acc3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      stub(AccountRepository, :update_position, fn _account, _position ->
        changeset = Account.position_changeset(acc3, %{position: "test"})
        changeset = Ecto.Changeset.add_error(changeset, :position, "has already been taken")
        {:error, changeset}
      end)

      assert {:error, changeset} = RepositionAccount.call(scope, acc3.external_id, acc1.external_id, acc2.external_id)

      assert Enum.any?(changeset.errors, fn
               {:position, {"has already been taken", _opts}} -> true
               _error -> false
             end)
    end

    test "handles non-position errors in changeset", %{book: book, acc1: acc1, acc2: acc2, acc3: acc3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      stub(AccountRepository, :update_position, fn _account, _position ->
        changeset = Account.position_changeset(acc3, %{position: "test"})
        changeset = Ecto.Changeset.add_error(changeset, :name, "is invalid")
        {:error, changeset}
      end)

      assert {:error, changeset} = RepositionAccount.call(scope, acc3.external_id, acc1.external_id, acc2.external_id)

      refute Enum.any?(changeset.errors, fn
               {:position, {"has already been taken", _opts}} -> true
               _error -> false
             end)
    end
  end
end
