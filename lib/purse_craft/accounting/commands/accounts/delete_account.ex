defmodule PurseCraft.Accounting.Commands.Accounts.DeleteAccount do
  @moduledoc """
  Deletes an existing account (hard delete).
  """

  alias PurseCraft.Accounting.Commands.Accounts.FetchAccountByExternalId
  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Identity.Schemas.Book
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub.BroadcastBook

  @doc """
  Deletes an existing account (hard delete).

  ## Examples

      iex> DeleteAccount.call(scope, book, "account-uuid")
      {:ok, %Account{}}

      iex> DeleteAccount.call(scope, book, "invalid-uuid")
      {:error, :not_found}

  """
  @spec call(Scope.t(), Book.t(), String.t()) ::
          {:ok, Account.t()} | {:error, atom() | Ecto.Changeset.t()}
  def call(%Scope{} = scope, %Book{} = book, external_id) when is_binary(external_id) do
    with :ok <- Policy.authorize(:account_delete, scope, %{book: book}),
         {:ok, account} <- FetchAccountByExternalId.call(scope, book, external_id),
         {:ok, deleted_account} <- AccountRepository.delete(account) do
      BroadcastBook.call(book, {:account_deleted, deleted_account})
      {:ok, deleted_account}
    end
  end
end
