defmodule PurseCraft.Budgeting.Policy.Checks do
  @moduledoc """
  `LetMe.Policy` check module for the `Budgeting` schema
  """

  import Ecto.Query

  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Budgeting.Schemas.BookUser
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

  def own_resource(_scope, _object), do: false

  @spec role(Scope.t(), any(), atom()) :: boolean()
  def role(%Scope{user: %User{} = user}, %{book: %Book{} = book}, role) do
    case get_book_user(book, user) do
      nil ->
        false

      book_user ->
        role == book_user.role
    end
  end

  def role(_scope, _object, _role), do: false

  defp get_book_user(%Book{id: nil, external_id: book_external_id}, %User{id: user_id}) do
    BookUser
    |> join(:inner, [bu], b in Book, on: bu.book_id == b.id)
    |> where([_bu, b], b.external_id == ^book_external_id)
    |> where([bu], bu.user_id == ^user_id)
    |> Repo.one()
  end

  defp get_book_user(%Book{id: id}, %User{id: user_id}) do
    BookUser
    |> join(:inner, [bu], b in Book, on: bu.book_id == b.id)
    |> where([_bu, b], b.id == ^id)
    |> where([bu], bu.user_id == ^user_id)
    |> Repo.one()
  end

  defp get_book_user(_book, _user), do: nil
end
