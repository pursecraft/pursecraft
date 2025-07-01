defmodule PurseCraft.Accounting.Commands.Accounts.ListAccounts do
  @moduledoc """
  Lists all accounts for a workspace.
  """

  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Types

  @type list_option :: {:preload, Types.preload()} | {:active_only, boolean()}
  @type list_options :: [list_option()]

  @doc """
  Lists all accounts for a workspace.

  ## Examples

      iex> ListAccounts.call(authorized_scope, workspace)
      [%Account{}]

      iex> ListAccounts.call(authorized_scope, workspace, preload: [:workspace])
      [%Account{workspace: %Workspace{}}]

      iex> ListAccounts.call(unauthorized_scope, workspace)
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Workspace.t(), list_options()) ::
          list(Account.t()) | {:error, :unauthorized}
  def call(%Scope{} = scope, %Workspace{} = workspace, opts \\ []) do
    with :ok <- Policy.authorize(:account_read, scope, %{workspace: workspace}) do
      AccountRepository.list_by_workspace(workspace.id, opts)
    end
  end
end
