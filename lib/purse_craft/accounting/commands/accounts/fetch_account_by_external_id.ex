defmodule PurseCraft.Accounting.Commands.Accounts.FetchAccountByExternalId do
  @moduledoc """
  Fetches an account by external ID with proper authorization.
  """

  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Utilities

  @type option :: {:preload, list()} | {:active_only, boolean()}
  @type options :: [option()]

  @doc """
  Fetches an account by external ID.

  ## Examples

      iex> FetchAccountByExternalId.call(scope, workspace, "account-uuid")
      {:ok, %Account{}}

      iex> FetchAccountByExternalId.call(scope, workspace, "invalid-uuid")
      {:error, :not_found}

      iex> FetchAccountByExternalId.call(unauthorized_scope, workspace, "account-uuid")
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Workspace.t(), String.t(), options()) :: {:ok, Account.t()} | {:error, atom()}
  def call(scope, workspace, external_id, opts \\ []) do
    with :ok <- Policy.authorize(:account_read, scope, %{workspace: workspace}) do
      external_id
      |> AccountRepository.get_by_external_id(opts)
      |> Utilities.to_result()
    end
  end
end
