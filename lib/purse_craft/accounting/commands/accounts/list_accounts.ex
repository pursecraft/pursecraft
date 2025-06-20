defmodule PurseCraft.Accounting.Commands.Accounts.ListAccounts do
  @moduledoc """
  Returns a list of accounts for a given book.
  """

  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Accounting.Schemas.Book
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Types

  @type option :: {:preload, Types.preload()} | {:active_only, boolean()}
  @type options :: [option()]

  @doc """
  Returns a list of accounts for a given book.

  ## Options

  - `:preload` - Associations to preload (default: [])
  - `:active_only` - Filter to only active (non-closed) accounts (default: true)

  ## Examples

      iex> ListAccounts.call(authorized_scope, book)
      [%Account{}, ...]

      iex> ListAccounts.call(authorized_scope, book, preload: [:book])
      [%Account{book: %Book{}}, ...]

      iex> ListAccounts.call(authorized_scope, book, active_only: false)
      [%Account{}, %Account{closed_at: ~U[2023-01-01 00:00:00Z]}]

      iex> ListAccounts.call(unauthorized_scope, book)
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Book.t(), options()) :: list(Account.t()) | {:error, :unauthorized}
  def call(%Scope{} = scope, %Book{} = book, opts \\ []) do
    with :ok <- Policy.authorize(:account_read, scope, %{book: book}) do
      AccountRepository.list_by_book(book.id, opts)
    end
  end
end
