defmodule PurseCraft.Accounting.Commands.Accounts.DeleteAccount do
  @moduledoc """
  Deletes an account for a workspace.
  """

  alias PurseCraft.Accounting.Commands.Accounts.FetchAccountByExternalId
  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub

  @doc """
  Deletes an account for a workspace.

  ## Examples

      iex> DeleteAccount.call(authorized_scope, workspace, "account-uuid")
      {:ok, %Account{}}

      iex> DeleteAccount.call(unauthorized_scope, workspace, "account-uuid")
      {:error, :unauthorized}

      iex> DeleteAccount.call(authorized_scope, workspace, "invalid-uuid")
      {:error, :not_found}

  """
  @spec call(Scope.t(), Workspace.t(), String.t()) ::
          {:ok, Account.t()} | {:error, :unauthorized | :not_found | Ecto.Changeset.t()}
  def call(%Scope{} = scope, %Workspace{} = workspace, external_id) do
    with :ok <- Policy.authorize(:account_delete, scope, %{workspace: workspace}),
         {:ok, account} <- FetchAccountByExternalId.call(scope, workspace, external_id),
         {:ok, deleted_account} <- AccountRepository.delete(account) do
      PubSub.broadcast_workspace(workspace, {:account_deleted, deleted_account})

      {:ok, deleted_account}
    end
  end
end
