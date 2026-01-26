defmodule PurseCraft.Identity.Aggregates.Token do
  @moduledoc false

  alias PurseCraft.Identity.Commands.ConsumeToken
  alias PurseCraft.Identity.Commands.CreateSessionToken
  alias PurseCraft.Identity.Commands.DeleteToken
  alias PurseCraft.Identity.Commands.RequestMagicLink
  alias PurseCraft.Identity.Events.MagicLinkRequested
  alias PurseCraft.Identity.Events.SessionTokenCreated
  alias PurseCraft.Identity.Events.TokenConsumed
  alias PurseCraft.Identity.Events.TokenDeleted

  @token_durations %{
    session: 60 * 60 * 24 * 7,
    magic_link: 60 * 15,
    email_change: 60 * 60,
    email_confirmation: 60 * 60 * 24 * 3
  }

  @consumable_types [:magic_link, :email_change, :email_confirmation]

  defstruct [
    :token,
    :user_uuid,
    :type,
    :email,
    :expires_at,
    :consumed_at,
    :metadata
  ]

  @type t :: %__MODULE__{
          token: String.t() | nil,
          user_uuid: String.t() | nil,
          type: atom() | nil,
          email: String.t() | nil,
          expires_at: DateTime.t() | nil,
          consumed_at: DateTime.t() | nil,
          metadata: map() | nil
        }

  @spec execute(t(), struct()) :: {:ok, struct()} | {:error, atom()}
  def execute(%__MODULE__{token: nil}, %RequestMagicLink{} = command) do
    token = Commanded.UUID.uuid4()
    expires_at = expires_at(:magic_link)

    event = %MagicLinkRequested{
      token: token,
      user_uuid: command.user_uuid,
      email: command.email,
      expires_at: expires_at
    }

    {:ok, event}
  end

  def execute(%__MODULE__{token: nil}, %CreateSessionToken{} = command) do
    token = Commanded.UUID.uuid4()
    token_type = command.token_type || :session
    expires_at = expires_at(token_type)

    event = %SessionTokenCreated{
      token: token,
      user_uuid: command.user_uuid,
      user_agent: command.user_agent,
      ip_address: command.ip_address,
      expires_at: expires_at
    }

    {:ok, event}
  end

  def execute(%__MODULE__{token: token} = aggregate, %ConsumeToken{}) do
    cond do
      aggregate.consumed_at != nil ->
        {:error, :already_consumed}

      expired?(aggregate) ->
        {:error, :expired}

      not consumable?(aggregate.type) ->
        {:error, :not_consumable}

      true ->
        event = %TokenConsumed{
          token: token,
          consumed_at: DateTime.utc_now(:second)
        }

        {:ok, event}
    end
  end

  def execute(%__MODULE__{token: token}, %DeleteToken{}) do
    event = %TokenDeleted{token: token}
    {:ok, event}
  end

  @spec apply_event(t(), struct()) :: t()

  def apply_event(%__MODULE__{} = token, %MagicLinkRequested{} = event) do
    %{
      token
      | token: event.token,
        user_uuid: event.user_uuid,
        type: :magic_link,
        email: event.email,
        expires_at: event.expires_at
    }
  end

  def apply_event(%__MODULE__{} = token, %SessionTokenCreated{} = event) do
    %{
      token
      | token: event.token,
        user_uuid: event.user_uuid,
        type: :session,
        expires_at: event.expires_at
    }
  end

  def apply_event(%__MODULE__{} = token, %TokenConsumed{} = event) do
    %{token | consumed_at: event.consumed_at}
  end

  def apply_event(%__MODULE__{} = token, %TokenDeleted{}) do
    %{token | token: nil}
  end

  # Private functions

  defp expires_at(token_type) do
    seconds = Map.get(@token_durations, token_type, @token_durations.session)

    :second
    |> DateTime.utc_now()
    |> DateTime.add(seconds, :second)
  end

  defp consumable?(type), do: type in @consumable_types

  defp expired?(%__MODULE__{expires_at: expires_at}) do
    DateTime.before?(expires_at, DateTime.utc_now(:second))
  end
end
