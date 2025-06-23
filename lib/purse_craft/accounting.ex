defmodule PurseCraft.Accounting do
  @moduledoc """
  The Accounting context.
  """

  alias PurseCraft.Accounting.Commands.Accounts.ListAccounts
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Identity.Schemas.Book
  alias PurseCraft.Identity.Schemas.Scope

  @doc """
  Lists accounts for a book.

  ## Examples

      iex> list_accounts(authorized_scope, book)
      [%Account{}, ...]

      iex> list_accounts(unauthorized_scope, book)
      {:error, :unauthorized}

  """
  @spec list_accounts(Scope.t(), Book.t(), keyword()) :: 
    [Account.t()] | {:error, :unauthorized}
  defdelegate list_accounts(scope, book, opts \\ []), to: ListAccounts, as: :call
end