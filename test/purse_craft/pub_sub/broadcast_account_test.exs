defmodule PurseCraft.PubSub.BroadcastAccountTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.AccountingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastAccount

  setup do
    user = IdentityFactory.insert(:user)
    workspace = CoreFactory.insert(:workspace)
    account = AccountingFactory.insert(:account, workspace: workspace)

    {:ok, user: user, workspace: workspace, account: account}
  end

  describe "call/2" do
    test "broadcasts :created message for account", %{account: account} do
      Phoenix.PubSub.subscribe(PurseCraft.PubSub, "account:#{account.external_id}")

      assert :ok = BroadcastAccount.call(account, {:created, account})

      assert_receive {:created, ^account}
    end

    test "broadcasts :updated message for account", %{account: account} do
      Phoenix.PubSub.subscribe(PurseCraft.PubSub, "account:#{account.external_id}")

      assert :ok = BroadcastAccount.call(account, {:updated, account})

      assert_receive {:updated, ^account}
    end

    test "broadcasts :deleted message for account", %{account: account} do
      Phoenix.PubSub.subscribe(PurseCraft.PubSub, "account:#{account.external_id}")

      assert :ok = BroadcastAccount.call(account, {:deleted, account})

      assert_receive {:deleted, ^account}
    end

    test "broadcasts :closed message for account", %{account: account} do
      Phoenix.PubSub.subscribe(PurseCraft.PubSub, "account:#{account.external_id}")

      assert :ok = BroadcastAccount.call(account, {:closed, account})

      assert_receive {:closed, ^account}
    end

    test "broadcasts :repositioned message for account", %{account: account} do
      Phoenix.PubSub.subscribe(PurseCraft.PubSub, "account:#{account.external_id}")

      assert :ok = BroadcastAccount.call(account, {:repositioned, account})

      assert_receive {:repositioned, ^account}
    end
  end
end
