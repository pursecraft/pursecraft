defmodule PurseCraft.Identity.Queries.TokenQuery do
  @moduledoc false
  use PurseCraft.Query

  import Ecto.Query

  alias PurseCraft.Identity.ReadModels.Token

  @spec by_token(binary()) :: Ecto.Query.t()
  def by_token(token) do
    by_token(Token, token)
  end

  @spec by_token(Ecto.Queryable.t(), binary()) :: Ecto.Query.t()
  def by_token(queryable, token) do
    from(t in queryable, where: t.token == ^token)
  end

  @spec by_context(String.t()) :: Ecto.Query.t()
  def by_context(context) do
    by_context(Token, context)
  end

  @spec by_context(Ecto.Queryable.t(), String.t()) :: Ecto.Query.t()
  def by_context(queryable, context) do
    from(t in queryable, where: t.context == ^context)
  end

  @spec by_user_uuid(String.t()) :: Ecto.Query.t()
  def by_user_uuid(user_uuid) do
    by_user_uuid(Token, user_uuid)
  end

  @spec by_user_uuid(Ecto.Queryable.t(), String.t()) :: Ecto.Query.t()
  def by_user_uuid(queryable, user_uuid) do
    from(t in queryable, where: t.user_uuid == ^user_uuid)
  end

  @spec not_expired() :: Ecto.Query.t()
  def not_expired do
    not_expired(Token)
  end

  @spec not_expired(Ecto.Queryable.t()) :: Ecto.Query.t()
  def not_expired(queryable) do
    from(t in queryable, where: t.expires_at > ^DateTime.utc_now())
  end

  @spec not_consumed() :: Ecto.Query.t()
  def not_consumed do
    not_consumed(Token)
  end

  @spec not_consumed(Ecto.Queryable.t()) :: Ecto.Query.t()
  def not_consumed(queryable) do
    from(t in queryable, where: is_nil(t.consumed_at))
  end

  @spec active() :: Ecto.Query.t()
  def active do
    active(Token)
  end

  @spec active(Ecto.Queryable.t()) :: Ecto.Query.t()
  def active(queryable) do
    queryable
    |> not_expired()
    |> not_consumed()
  end
end
