defmodule PurseCraft.Accounting.Commands.Accounts.CloseAccount do
  @moduledoc """
  Closes an existing account (business closure with closed_at timestamp).
  """

  alias PurseCraft.Accounting.Commands.Accounts.FetchAccountByExternalId
  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Accounting.Schemas.Book
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub.BroadcastBook

  @doc """
  Closes an existing account (business closure with closed_at timestamp).

  ## Examples

      iex> CloseAccount.call(scope, book, "account-uuid")
      {:ok, %Account{}}

      iex> CloseAccount.call(scope, book, "invalid-uuid")
      {:error, :not_found}

  """
  @spec call(Scope.t(), Book.t(), String.t()) ::
          {:ok, Account.t()} | {:error, atom() | Ecto.Changeset.t()}
  def call(%Scope{} = scope, %Book{} = book, external_id) when is_binary(external_id) do
    with :ok <- Policy.authorize(:account_update, scope, %{book: book}),
         {:ok, account} <- FetchAccountByExternalId.call(scope, book, external_id),
         {:ok, closed_account} <- AccountRepository.close(account) do
      BroadcastBook.call(book, {:account_closed, closed_account})
      {:ok, closed_account}
    end
  end
end
