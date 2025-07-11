defmodule PurseCraft.PubSub.SubscribeAccount do
  @moduledoc """
  Subscribes to notifications about changes for a specific account.
  """

  alias PurseCraft.Accounting.Schemas.Account

  @spec call(Account.t()) :: :ok | {:error, term()}
  def call(%Account{external_id: external_id}) do
    Phoenix.PubSub.subscribe(PurseCraft.PubSub, "account:#{external_id}")
  end
end
