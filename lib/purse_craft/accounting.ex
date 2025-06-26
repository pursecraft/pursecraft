defmodule PurseCraft.Accounting do
  @moduledoc """
  The Accounting context.
  """

  alias PurseCraft.Accounting.Commands.Accounts.CreateAccount
  alias PurseCraft.Accounting.Commands.Accounts.FetchAccountByExternalId

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
end
