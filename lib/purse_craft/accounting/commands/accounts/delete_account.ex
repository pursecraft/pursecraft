defmodule PurseCraft.Accounting.Commands.Accounts.DeleteAccount do
  @moduledoc """
  Deletes an account for a book.
  """

  alias PurseCraft.Accounting.Commands.Accounts.FetchAccountByExternalId
  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Core.Schemas.Book
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub

  @doc """
  Deletes an account for a book.

  ## Examples

      iex> DeleteAccount.call(authorized_scope, book, "account-uuid")
      {:ok, %Account{}}

      iex> DeleteAccount.call(unauthorized_scope, book, "account-uuid")
      {:error, :unauthorized}

      iex> DeleteAccount.call(authorized_scope, book, "invalid-uuid")
      {:error, :not_found}

  """
  @spec call(Scope.t(), Book.t(), String.t()) ::
          {:ok, Account.t()} | {:error, :unauthorized | :not_found | Ecto.Changeset.t()}
  def call(%Scope{} = scope, %Book{} = book, external_id) do
    with :ok <- Policy.authorize(:account_delete, scope, %{book: book}),
         {:ok, account} <- FetchAccountByExternalId.call(scope, book, external_id),
         {:ok, deleted_account} <- AccountRepository.delete(account) do
      PubSub.broadcast_book(book, {:account_deleted, deleted_account})

      {:ok, deleted_account}
    end
  end
end
