defmodule PurseCraft.Accounting.Commands.Transactions.FetchTransaction do
  @moduledoc """
  Fetches a transaction by struct or external ID with proper authorization.

  This is the unified entry point for fetching transactions - it handles:
  - Passing an existing `%Transaction{}` struct (returns as-is or reloads with preloads)
  - Passing a UUID string (queries by external_id)
  """

  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.TransactionRepository
  alias PurseCraft.Accounting.Schemas.Transaction
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Utilities

  @type id_or_struct :: Transaction.t() | integer() | Ecto.UUID.t()
  @type option :: {:preload, list()}
  @type options :: [option()]

  @doc """
  Fetches a transaction by struct or external ID.

  ## Parameters

  - `scope` - Authorization scope
  - `workspace` - Workspace context for authorization
  - `id_or_struct` - Can be:
    - `%Transaction{}` - Returns the struct as-is (useful for pipelines)
    - `integer()` - Fetches by internal database ID
    - `binary()` - Fetches by external_id (UUID string)
  - `opts` - Optional keyword list:
    - `:preload` - Associations to preload (e.g., [:transaction_lines])

  ## Examples

      # Fetch by external_id (UUID string)
      iex> FetchTransaction.call(scope, workspace, "550e8400-e29b-41d4-a716-446655440000")
      {:ok, %Transaction{}}

      # Fetch by integer ID
      iex> FetchTransaction.call(scope, workspace, 123)
      {:ok, %Transaction{}}

      # Pass through existing struct
      iex> transaction = %Transaction{id: 123}
      iex> FetchTransaction.call(scope, workspace, transaction)
      {:ok, %Transaction{id: 123}}

      # Not found
      iex> FetchTransaction.call(scope, workspace, "non-existent-uuid")
      {:error, :not_found}

      # Unauthorized
      iex> FetchTransaction.call(unauthorized_scope, workspace, "550e8400-e29b-41d4-a716-446655440000")
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Workspace.t(), id_or_struct(), options()) ::
          {:ok, Transaction.t()} | {:error, :not_found | :unauthorized}

  def call(scope, workspace, id_or_struct, opts \\ [])

  def call(%Scope{} = scope, %Workspace{} = workspace, %Transaction{} = transaction, opts) do
    with :ok <- Policy.authorize(:transaction_read, scope, %{workspace: workspace}) do
      if Keyword.get(opts, :preload) do
        transaction.external_id
        |> TransactionRepository.get_by_external_id(opts)
        |> Utilities.to_result()
      else
        {:ok, transaction}
      end
    end
  end

  def call(%Scope{} = scope, %Workspace{} = workspace, id, opts) when is_integer(id) do
    with :ok <- Policy.authorize(:transaction_read, scope, %{workspace: workspace}),
         {:ok, transaction} <- fetch_and_convert(id, opts, :by_id) do
      if transaction.workspace_id == workspace.id do
        {:ok, transaction}
      else
        {:error, :not_found}
      end
    end
  end

  def call(%Scope{} = scope, %Workspace{} = workspace, external_id, opts) when is_binary(external_id) do
    with :ok <- Policy.authorize(:transaction_read, scope, %{workspace: workspace}),
         {:ok, transaction} <- fetch_and_convert(external_id, opts, :by_external_id) do
      if transaction.workspace_id == workspace.id do
        {:ok, transaction}
      else
        {:error, :not_found}
      end
    end
  end

  defp fetch_and_convert(id, opts, :by_id) do
    id
    |> TransactionRepository.get_by_id(opts)
    |> Utilities.to_result()
  end

  defp fetch_and_convert(external_id, opts, :by_external_id) do
    external_id
    |> TransactionRepository.get_by_external_id(opts)
    |> Utilities.to_result()
  end
end
