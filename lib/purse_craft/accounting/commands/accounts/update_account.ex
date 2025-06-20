defmodule PurseCraft.Accounting.Commands.Accounts.UpdateAccount do
  @moduledoc """
  Updates an existing account.
  """

  alias PurseCraft.Accounting.Commands.Accounts.FetchAccountByExternalId
  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Accounting.Schemas.Book
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub.BroadcastBook
  alias PurseCraft.Utilities

  @type update_attrs :: %{
          optional(:name) => String.t(),
          optional(:description) => String.t()
        }

  @doc """
  Updates an existing account.

  ## Examples

      iex> UpdateAccount.call(scope, book, "account-uuid", %{name: "Updated Name"})
      {:ok, %Account{}}

      iex> UpdateAccount.call(scope, book, "invalid-uuid", %{name: "Updated Name"})
      {:error, :not_found}

  """
  @spec call(Scope.t(), Book.t(), String.t(), update_attrs()) ::
          {:ok, Account.t()} | {:error, atom() | Ecto.Changeset.t()}
  def call(%Scope{} = scope, %Book{} = book, external_id, attrs) when is_binary(external_id) and is_map(attrs) do
    with :ok <- Policy.authorize(:account_update, scope, %{book: book}),
         {:ok, account} <- FetchAccountByExternalId.call(scope, book, external_id),
         attrs = Utilities.atomize_keys(attrs),
         {:ok, updated_account} <- AccountRepository.update(account, attrs) do
      BroadcastBook.call(book, {:account_updated, updated_account})
      {:ok, updated_account}
    end
  end
end
