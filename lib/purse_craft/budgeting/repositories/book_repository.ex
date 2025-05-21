defmodule PurseCraft.Budgeting.Repositories.BookRepository do
  @moduledoc """
  Repository for `Book`.
  """

  alias PurseCraft.Budgeting.Queries.BookQueries
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Repo

  @doc """
  Lists all books for a specific user.

  ## Examples

      iex> list_by_user(user_id)
      [%Book{}, ...]

  """
  @spec list_by_user(integer()) :: list(Book.t())
  def list_by_user(user_id) do
    user_id
    |> BookQueries.by_user()
    |> Repo.all()
  end

  @doc """
  Gets a book by its external ID.

  Raises `Ecto.NoResultsError` if the Book does not exist.

  ## Examples

      iex> get_by_external_id!("abcd-1234")
      %Book{}

      iex> get_by_external_id!("non-existent-id")
      ** (Ecto.NoResultsError)

  """
  @spec get_by_external_id!(Ecto.UUID.t()) :: Book.t()
  def get_by_external_id!(external_id) do
    external_id
    |> BookQueries.by_external_id()
    |> Repo.one!()
  end
end
