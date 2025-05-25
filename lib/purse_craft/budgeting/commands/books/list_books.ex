defmodule PurseCraft.Budgeting.Commands.Books.ListBooks do
  @moduledoc """
  Lists books associated with the scope's user.
  """

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.BookRepository
  alias PurseCraft.Budgeting.Schemas.Book
  alias PurseCraft.Identity.Schemas.Scope

  @doc """
  Lists books associated with the scope's user.

  ## Examples

      iex> call(authorized_scope)
      [%Book{}, ...]

      iex> call(unauthorized_scope)
      {:error, :unauthorized}

  """
  @spec call(Scope.t()) :: list(Book.t()) | {:error, :unauthorized}
  def call(%Scope{} = scope) do
    with :ok <- Policy.authorize(:book_list, scope) do
      BookRepository.list_by_user(scope.user.id)
    end
  end
end
