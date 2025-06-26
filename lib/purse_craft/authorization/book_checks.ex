defmodule PurseCraft.Authorization.BookChecks do
  @moduledoc """
  Shared book-level authorization checks used across contexts
  """

  import Ecto.Query

  alias PurseCraft.Cache
  alias PurseCraft.Core.Schemas.Book
  alias PurseCraft.Core.Schemas.BookUser
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Identity.Schemas.User
  alias PurseCraft.Repo

  @spec own_resource(Scope.t(), any()) :: boolean()
  def own_resource(%Scope{user: %User{} = user}, %{book: %Book{} = book}) do
    case get_book_user(book, user) do
      nil ->
        false

      _book_user ->
        true
    end
  end

  # coveralls-ignore-start
  def own_resource(_scope, _object), do: false
  # coveralls-ignore-stop

  @spec role(Scope.t(), any(), atom()) :: boolean()
  def role(%Scope{user: %User{} = user}, %{book: %Book{} = book}, role) do
    case get_book_user(book, user) do
      nil ->
        false

      book_user ->
        role == book_user.role
    end
  end

  # coveralls-ignore-start
  def role(_scope, _object, _role), do: false
  # coveralls-ignore-stop

  defp get_book_user(%Book{id: nil, external_id: book_external_id}, %User{id: user_id}) do
    cache_key = {:authorization_check, {:book_user, {:book_external_id, {book_external_id, user_id}}}}

    case Cache.get(cache_key) do
      nil ->
        book_user =
          BookUser
          |> join(:inner, [bu], b in Book, on: bu.book_id == b.id)
          |> where([_bu, b], b.external_id == ^book_external_id)
          |> where([bu], bu.user_id == ^user_id)
          |> Repo.one()

        Cache.put(cache_key, book_user)
        book_user

      cached_book_user ->
        cached_book_user
    end
  end

  defp get_book_user(%Book{id: book_id}, %User{id: user_id}) do
    cache_key = {:authorization_check, {:book_user, {:book_id, {book_id, user_id}}}}

    case Cache.get(cache_key) do
      nil ->
        book_user =
          BookUser
          |> join(:inner, [bu], b in Book, on: bu.book_id == b.id)
          |> where([_bu, b], b.id == ^book_id)
          |> where([bu], bu.user_id == ^user_id)
          |> Repo.one()

        Cache.put(cache_key, book_user)
        book_user

      cached_book_user ->
        cached_book_user
    end
  end

  # coveralls-ignore-start
  defp get_book_user(_book, _user), do: nil
  # coveralls-ignore-stop
end
