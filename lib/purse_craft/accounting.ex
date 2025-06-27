defmodule PurseCraft.Accounting do
  @moduledoc """
  The Accounting context.
  """

  alias PurseCraft.Accounting.Commands.Accounts.CloseAccount
  alias PurseCraft.Accounting.Commands.Accounts.CreateAccount
  alias PurseCraft.Accounting.Commands.Accounts.DeleteAccount
  alias PurseCraft.Accounting.Commands.Accounts.FetchAccountByExternalId
  alias PurseCraft.Accounting.Commands.Accounts.ListAccounts
  alias PurseCraft.Accounting.Commands.Accounts.RepositionAccount
  alias PurseCraft.Accounting.Commands.Accounts.UpdateAccount

  @doc """
  Creates an account and associates it with the given `Book`.

  ## Examples

      iex> create_account(scope, book, %{name: "Checking Account", account_type: "checking"})
      {:ok, %Account{}}

      iex> create_account(scope, book, %{name: "", account_type: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  # coveralls-ignore-next-line
  defdelegate create_account(scope, book, attrs \\ %{}), to: CreateAccount, as: :call

  @doc """
  Fetches an account by external ID.

  ## Examples

      iex> fetch_account_by_external_id(scope, book, "account-uuid")
      {:ok, %Account{}}

      iex> fetch_account_by_external_id(scope, book, "invalid-uuid")
      {:error, :not_found}

  """
  # coveralls-ignore-next-line
  defdelegate fetch_account_by_external_id(scope, book, external_id, opts \\ []),
    to: FetchAccountByExternalId,
    as: :call

  @doc """
  Lists all accounts for a book.

  ## Examples

      iex> list_accounts(scope, book)
      [%Account{}, %Account{}]

      iex> list_accounts(scope, book, preload: [:book])
      [%Account{book: %Book{}}, %Account{book: %Book{}}]

  """
  # coveralls-ignore-next-line
  defdelegate list_accounts(scope, book, opts \\ []), to: ListAccounts, as: :call

  @doc """
  Updates an account for a book.

  ## Examples

      iex> update_account(scope, book, "account-uuid", %{name: "New Name"})
      {:ok, %Account{}}

      iex> update_account(scope, book, "account-uuid", %{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  # coveralls-ignore-next-line
  defdelegate update_account(scope, book, external_id, attrs), to: UpdateAccount, as: :call

  @doc """
  Deletes an account for a book.

  ## Examples

      iex> delete_account(scope, book, "account-uuid")
      {:ok, %Account{}}

      iex> delete_account(scope, book, "invalid-uuid")
      {:error, :not_found}

  """
  # coveralls-ignore-next-line
  defdelegate delete_account(scope, book, external_id), to: DeleteAccount, as: :call

  @doc """
  Closes an account for a book by setting the closed_at timestamp.

  ## Examples

      iex> close_account(scope, book, "account-uuid")
      {:ok, %Account{closed_at: ~U[2024-01-01 00:00:00Z]}}

      iex> close_account(scope, book, "invalid-uuid")
      {:error, :not_found}

  """
  # coveralls-ignore-next-line
  defdelegate close_account(scope, book, external_id), to: CloseAccount, as: :call

  @doc """
  Repositions an account between two other accounts using fractional indexing.

  ## Examples

      iex> reposition_account(scope, "acc-123", "acc-456", "acc-789")
      {:ok, %Account{position: "m"}}

      iex> reposition_account(scope, "acc-123", nil, "acc-456")
      {:ok, %Account{position: "g"}}

  """
  # coveralls-ignore-next-line
  defdelegate reposition_account(scope, account_id, prev_account_id, next_account_id), to: RepositionAccount, as: :call
end
