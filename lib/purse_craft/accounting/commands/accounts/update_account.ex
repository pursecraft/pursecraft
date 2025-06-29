defmodule PurseCraft.Accounting.Commands.Accounts.UpdateAccount do
  @moduledoc """
  Updates an account for a workspace.
  """

  alias PurseCraft.Accounting.Commands.Accounts.FetchAccountByExternalId
  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub

  @type update_attrs :: %{optional(:name) => String.t(), optional(:description) => String.t()}

  @doc """
  Updates an account for a workspace.

  ## Examples

      iex> UpdateAccount.call(authorized_scope, workspace, "account-uuid", %{name: "New Name"})
      {:ok, %Account{}}

      iex> UpdateAccount.call(authorized_scope, workspace, "account-uuid", %{name: ""})
      {:error, %Ecto.Changeset{}}

      iex> UpdateAccount.call(unauthorized_scope, workspace, "account-uuid", %{name: "New Name"})
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Workspace.t(), String.t(), update_attrs()) ::
          {:ok, Account.t()} | {:error, :unauthorized | :not_found | Ecto.Changeset.t()}
  def call(%Scope{} = scope, %Workspace{} = workspace, external_id, attrs) do
    with :ok <- Policy.authorize(:account_update, scope, %{workspace: workspace}),
         {:ok, account} <- FetchAccountByExternalId.call(scope, workspace, external_id),
         {:ok, updated_account} <- AccountRepository.update(account, attrs) do
      PubSub.broadcast_workspace(workspace, {:account_updated, updated_account})

      {:ok, updated_account}
    end
  end
end
