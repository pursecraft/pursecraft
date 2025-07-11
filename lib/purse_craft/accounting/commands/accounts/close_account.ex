defmodule PurseCraft.Accounting.Commands.Accounts.CloseAccount do
  @moduledoc """
  Closes an account for a workspace by setting the closed_at timestamp.
  """

  alias PurseCraft.Accounting.Commands.Accounts.FetchAccountByExternalId
  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub

  @doc """
  Closes an account for a workspace.

  Uses the :account_update authorization policy since closing is a form of update.

  ## Examples

      iex> CloseAccount.call(authorized_scope, workspace, "account-uuid")
      {:ok, %Account{closed_at: ~U[2024-01-01 00:00:00Z]}}

      iex> CloseAccount.call(unauthorized_scope, workspace, "account-uuid")
      {:error, :unauthorized}

      iex> CloseAccount.call(authorized_scope, workspace, "invalid-uuid")
      {:error, :not_found}

  """
  @spec call(Scope.t(), Workspace.t(), String.t()) ::
          {:ok, Account.t()} | {:error, :unauthorized | :not_found | Ecto.Changeset.t()}
  def call(%Scope{} = scope, %Workspace{} = workspace, external_id) do
    with :ok <- Policy.authorize(:account_update, scope, %{workspace: workspace}),
         {:ok, account} <- FetchAccountByExternalId.call(scope, workspace, external_id),
         {:ok, closed_account} <- AccountRepository.close(account) do
      PubSub.broadcast_workspace(workspace, {:account_closed, closed_account})
      PubSub.broadcast_account(closed_account, {:closed, closed_account})

      {:ok, closed_account}
    end
  end
end
