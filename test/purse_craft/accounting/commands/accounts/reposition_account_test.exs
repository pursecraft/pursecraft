defmodule PurseCraft.Accounting.Commands.Accounts.RepositionAccountTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Accounting.Commands.Accounts.RepositionAccount
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.AccountingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastWorkspace

  setup do
    workspace = CoreFactory.insert(:workspace)

    acc1 = AccountingFactory.insert(:account, workspace: workspace, position: "g")
    acc2 = AccountingFactory.insert(:account, workspace: workspace, position: "m")
    acc3 = AccountingFactory.insert(:account, workspace: workspace, position: "t")

    %{
      workspace: workspace,
      acc1: acc1,
      acc2: acc2,
      acc3: acc3
    }
  end

  describe "call/4" do
    test "successfully repositions account between two others", %{
      workspace: workspace,
      acc1: acc1,
      acc2: acc2,
      acc3: acc3
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, updated} = RepositionAccount.call(scope, acc3.external_id, acc1.external_id, acc2.external_id)

      assert updated.id == acc3.id
      assert updated.position > acc1.position
      assert updated.position < acc2.position
    end

    test "repositions account to the beginning when prev_account_id is nil", %{
      workspace: workspace,
      acc1: acc1,
      acc3: acc3
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, updated} = RepositionAccount.call(scope, acc3.external_id, nil, acc1.external_id)

      assert updated.id == acc3.id
      assert updated.position < acc1.position
    end

    test "repositions account to the end when next_account_id is nil", %{workspace: workspace, acc1: acc1, acc3: acc3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, updated} = RepositionAccount.call(scope, acc1.external_id, acc3.external_id, nil)

      assert updated.id == acc1.id
      assert updated.position > acc3.position
    end

    test "returns not_found when account doesn't exist", %{workspace: workspace, acc1: acc1, acc2: acc2} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :not_found} =
               RepositionAccount.call(scope, Ecto.UUID.generate(), acc1.external_id, acc2.external_id)
    end

    test "returns not_found when prev_account doesn't exist", %{workspace: workspace, acc1: acc1, acc2: acc2} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :not_found} =
               RepositionAccount.call(scope, acc1.external_id, Ecto.UUID.generate(), acc2.external_id)
    end

    test "returns not_found when next_account doesn't exist", %{workspace: workspace, acc1: acc1, acc2: acc2} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :not_found} =
               RepositionAccount.call(scope, acc1.external_id, acc2.external_id, Ecto.UUID.generate())
    end

    test "returns not_found when prev_account is from different workspace", %{
      workspace: workspace,
      acc1: acc1,
      acc2: acc2
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      other_workspace = CoreFactory.insert(:workspace)
      other_acc = AccountingFactory.insert(:account, workspace: other_workspace, position: "a")

      assert {:error, :not_found} =
               RepositionAccount.call(scope, acc1.external_id, other_acc.external_id, acc2.external_id)
    end

    test "returns unauthorized when user lacks permission", %{workspace: workspace, acc1: acc1, acc2: acc2, acc3: acc3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} =
               RepositionAccount.call(scope, acc3.external_id, acc1.external_id, acc2.external_id)
    end

    test "returns error when fractional indexing fails", %{workspace: workspace} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      acc1 = AccountingFactory.insert(:account, workspace: workspace, position: "z")
      acc2 = AccountingFactory.insert(:account, workspace: workspace, position: "a")
      acc3 = AccountingFactory.insert(:account, workspace: workspace, position: "n")

      assert {:error, :prev_must_be_less_than_next} =
               RepositionAccount.call(scope, acc3.external_id, acc1.external_id, acc2.external_id)
    end

    test "broadcasts account_repositioned event on success", %{workspace: workspace, acc1: acc1, acc2: acc2, acc3: acc3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      expect(BroadcastWorkspace, :call, fn received_workspace, {:account_repositioned, received_account} ->
        assert received_workspace.id == workspace.id
        assert received_account.id == acc3.id
        :ok
      end)

      assert {:ok, _updated} = RepositionAccount.call(scope, acc3.external_id, acc1.external_id, acc2.external_id)

      verify!()
    end

    test "handles unique constraint violation with retry", %{workspace: workspace, acc1: acc1, acc2: acc2, acc3: acc3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, updated} = RepositionAccount.call(scope, acc3.external_id, acc1.external_id, acc2.external_id)

      assert updated.id == acc3.id
      assert updated.position > acc1.position
      assert updated.position < acc2.position
    end

    test "returns error after max retries", %{workspace: workspace, acc1: acc1, acc2: acc2, acc3: acc3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
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

    test "handles non-position errors in changeset", %{workspace: workspace, acc1: acc1, acc2: acc2, acc3: acc3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
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
