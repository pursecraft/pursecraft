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
end
