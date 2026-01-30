defmodule PurseCraft.Identity.Queries.UserQuery do
  @moduledoc false
  use PurseCraft.Query

  import Ecto.Query

  alias PurseCraft.Identity.ReadModels.User

  @spec by_id(String.t()) :: Ecto.Query.t()
  def by_id(id) do
    by_id(User, id)
  end

  @spec by_id(Ecto.Queryable.t(), String.t()) :: Ecto.Query.t()
  def by_id(queryable, id) do
    from(u in queryable, where: u.id == ^id)
  end

  @spec by_email(String.t()) :: Ecto.Query.t()
  def by_email(email) do
    by_email(User, email)
  end

  @spec by_email(Ecto.Queryable.t(), String.t()) :: Ecto.Query.t()
  def by_email(queryable, email) do
    from(u in queryable, where: u.email == ^email)
  end
end
