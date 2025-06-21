defmodule PurseCraft.Accounting.Commands.Accounts.FetchAccountByExternalId do
  @moduledoc """
  Fetches an account by external ID from the given `Book`.
  """

  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Identity.Schemas.Book
  alias PurseCraft.Identity.Schemas.Scope

  @type fetch_option :: {:preload, list(atom())} | {:active_only, boolean()}
  @type fetch_options :: [fetch_option()]

  @doc """
  Fetches an account by external ID from the given `Book`.

  ## Options

  - `:preload` - Associations to preload (default: [])
  - `:active_only` - Filter to only active (non-closed) accounts (default: true)

  ## Examples

      iex> FetchAccountByExternalId.call(authorized_scope, book, "uuid-123")
      {:ok, %Account{}}

      iex> FetchAccountByExternalId.call(authorized_scope, book, "invalid-uuid")
      {:error, :not_found}

      iex> FetchAccountByExternalId.call(unauthorized_scope, book, "uuid-123")
      {:error, :unauthorized}

      iex> FetchAccountByExternalId.call(authorized_scope, book, "uuid-123", preload: [:book])
      {:ok, %Account{book: %Book{}}}

  """
  @spec call(Scope.t(), Book.t(), Ecto.UUID.t(), fetch_options()) ::
          {:ok, Account.t()} | {:error, :not_found} | {:error, :unauthorized}
  def call(%Scope{} = scope, %Book{} = book, external_id, opts \\ []) do
    with :ok <- Policy.authorize(:account_read, scope, %{book: book}) do
      case AccountRepository.get_by_external_id(book.id, external_id, opts) do
        nil -> {:error, :not_found}
        account -> {:ok, account}
      end
    end
  end
end
