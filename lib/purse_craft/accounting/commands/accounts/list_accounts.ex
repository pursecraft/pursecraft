defmodule PurseCraft.Accounting.Commands.Accounts.ListAccounts do
  @moduledoc """
  Lists all accounts for a book.
  """

  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Core.Schemas.Book
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Types

  @type list_option :: {:preload, Types.preload()} | {:active_only, boolean()}
  @type list_options :: [list_option()]

  @doc """
  Lists all accounts for a book.

  ## Examples

      iex> ListAccounts.call(authorized_scope, book)
      [%Account{}]

      iex> ListAccounts.call(authorized_scope, book, preload: [:book])
      [%Account{book: %Book{}}]

      iex> ListAccounts.call(unauthorized_scope, book)
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Book.t(), list_options()) ::
          list(Account.t()) | {:error, :unauthorized}
  def call(%Scope{} = scope, %Book{} = book, opts \\ []) do
    with :ok <- Policy.authorize(:account_read, scope, %{book: book}) do
      AccountRepository.list_by_book(book.id, opts)
    end
  end
end
