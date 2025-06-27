defmodule PurseCraft.Accounting.Commands.Accounts.CloseAccount do
  @moduledoc """
  Closes an account for a book by setting the closed_at timestamp.
  """

  alias PurseCraft.Accounting.Commands.Accounts.FetchAccountByExternalId
  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Core.Schemas.Book
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub

  @doc """
  Closes an account for a book.

  Uses the :account_update authorization policy since closing is a form of update.

  ## Examples

      iex> CloseAccount.call(authorized_scope, book, "account-uuid")
      {:ok, %Account{closed_at: ~U[2024-01-01 00:00:00Z]}}

      iex> CloseAccount.call(unauthorized_scope, book, "account-uuid")
      {:error, :unauthorized}

      iex> CloseAccount.call(authorized_scope, book, "invalid-uuid")
      {:error, :not_found}

  """
  @spec call(Scope.t(), Book.t(), String.t()) ::
          {:ok, Account.t()} | {:error, :unauthorized | :not_found | Ecto.Changeset.t()}
  def call(%Scope{} = scope, %Book{} = book, external_id) do
    with :ok <- Policy.authorize(:account_update, scope, %{book: book}),
         {:ok, account} <- FetchAccountByExternalId.call(scope, book, external_id),
         {:ok, closed_account} <- AccountRepository.close(account) do
      PubSub.broadcast_book(book, {:account_closed, closed_account})

      {:ok, closed_account}
    end
  end
end
