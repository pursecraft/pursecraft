defmodule PurseCraft.Accounting.Commands.Accounts.FetchAccount do
  @moduledoc """
  Fetches an account by struct, integer ID, or external ID with proper authorization.

  This is the unified entry point for fetching accounts - it handles all three cases:
  - Passing an existing `%Account{}` struct (returns as-is or reloads with preloads)
  - Passing an integer ID (queries by internal database ID)
  - Passing a UUID string (queries by external_id)
  """

  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Utilities

  @type id_or_struct :: Account.t() | integer() | Ecto.UUID.t()
  @type option :: {:preload, list()} | {:active_only, boolean()}
  @type options :: [option()]

  @doc """
  Fetches an account by struct, integer ID, or external ID.

  ## Parameters

  - `scope` - Authorization scope
  - `workspace` - Workspace context for authorization
  - `id_or_struct` - Can be:
    - `%Account{}` - Returns the struct as-is (useful for pipelines)
    - `integer()` - Fetches by internal database ID
    - `binary()` - Fetches by external_id (UUID string)
  - `opts` - Optional keyword list:
    - `:preload` - Associations to preload
    - `:active_only` - Only return active accounts (default: true)

  ## Examples

      # Fetch by external_id (UUID string)
      iex> FetchAccount.call(scope, workspace, "550e8400-e29b-41d4-a716-446655440000")
      {:ok, %Account{}}

      # Fetch by integer ID
      iex> FetchAccount.call(scope, workspace, 123)
      {:ok, %Account{}}

      # Pass through existing struct
      iex> account = %Account{id: 123}
      iex> FetchAccount.call(scope, workspace, account)
      {:ok, %Account{id: 123}}

      # Not found
      iex> FetchAccount.call(scope, workspace, "non-existent-uuid")
      {:error, :not_found}

      # Unauthorized
      iex> FetchAccount.call(unauthorized_scope, workspace, "550e8400-e29b-41d4-a716-446655440000")
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Workspace.t(), id_or_struct(), options()) ::
          {:ok, Account.t()} | {:error, :not_found | :unauthorized}

  def call(scope, workspace, id_or_struct, opts \\ [])

  def call(%Scope{} = scope, %Workspace{} = workspace, %Account{} = account, opts) do
    with :ok <- Policy.authorize(:account_read, scope, %{workspace: workspace}) do
      if Keyword.get(opts, :preload) do
        account.external_id
        |> AccountRepository.get_by_external_id(opts)
        |> Utilities.to_result()
      else
        {:ok, account}
      end
    end
  end

  def call(%Scope{} = scope, %Workspace{} = workspace, id, opts) when is_integer(id) do
    with :ok <- Policy.authorize(:account_read, scope, %{workspace: workspace}) do
      id
      |> AccountRepository.get_by_id(opts)
      |> Utilities.to_result()
    end
  end

  def call(%Scope{} = scope, %Workspace{} = workspace, external_id, opts) when is_binary(external_id) do
    with :ok <- Policy.authorize(:account_read, scope, %{workspace: workspace}) do
      external_id
      |> AccountRepository.get_by_external_id(opts)
      |> Utilities.to_result()
    end
  end
end
