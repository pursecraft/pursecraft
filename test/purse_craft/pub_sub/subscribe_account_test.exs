defmodule PurseCraft.PubSub.SubscribeAccountTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.AccountingFactory
  alias PurseCraft.PubSub

  describe "call/1" do
    test "subscribes to account changes" do
      account = AccountingFactory.build(:account)

      assert :ok = PubSub.subscribe_account(account)
    end
  end
end
