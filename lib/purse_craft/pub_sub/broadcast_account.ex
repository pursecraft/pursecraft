defmodule PurseCraft.PubSub.BroadcastAccount do
  @moduledoc """
  Broadcasts a message to all subscribers of a specific account.
  """

  alias PurseCraft.Accounting.Schemas.Account

  @type message ::
          {:created, Account.t()}
          | {:updated, Account.t()}
          | {:deleted, Account.t()}
          | {:closed, Account.t()}
          | {:repositioned, Account.t()}

  @spec call(Account.t(), message()) :: :ok | {:error, term()}
  def call(%Account{external_id: external_id}, message) do
    Phoenix.PubSub.broadcast(PurseCraft.PubSub, "account:#{external_id}", message)
  end
end
