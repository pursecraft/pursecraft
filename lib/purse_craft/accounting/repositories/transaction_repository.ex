defmodule PurseCraft.Accounting.Repositories.TransactionRepository do
  @moduledoc """
  Repository for `Transaction`.
  """

  alias PurseCraft.Accounting.Queries.TransactionQuery
  alias PurseCraft.Accounting.Schemas.Transaction
  alias PurseCraft.Accounting.Schemas.TransactionLine
  alias PurseCraft.Repo
  alias PurseCraft.Types
  alias PurseCraft.Utilities

  @type transaction_line_attrs :: %{
          required(:amount) => integer(),
          optional(:memo) => String.t(),
          optional(:envelope_id) => integer() | nil,
          optional(:payee_id) => integer() | nil
        }

  @type create_attrs :: %{
          required(:date) => Date.t(),
          required(:amount) => integer(),
          required(:account_id) => integer(),
          required(:workspace_id) => integer(),
          optional(:memo) => String.t(),
          optional(:cleared) => boolean(),
          optional(:payee_id) => integer() | nil,
          required(:lines) => [transaction_line_attrs()]
        }

  @type create_option :: {:preload, Types.preload()}
  @type create_options :: [create_option()]

  @type get_option :: {:preload, Types.preload()}
  @type get_options :: [get_option()]

  @type list_option :: {:preload, Types.preload()} | {:limit, integer()}
  @type list_options :: [list_option()]

  @doc """
  Creates a transaction with associated transaction lines atomically.

  Every transaction must have at least one transaction line. This function handles
  both simple and split transactions by creating the transaction record first,
  then creating all associated lines within a database transaction.

  ## Examples

      # Simple transaction (single line)
      iex> create(%{
      ...>   date: ~D[2025-01-15],
      ...>   amount: -2500,
      ...>   account_id: 1,
      ...>   workspace_id: 1,
      ...>   memo: "Groceries",
      ...>   payee_id: 2,
      ...>   lines: [
      ...>     %{amount: -2500, envelope_id: 3}
      ...>   ]
      ...> })
      {:ok, %Transaction{transaction_lines: [%TransactionLine{}]}}

      # Split transaction (multiple lines)
      iex> create(%{
      ...>   date: ~D[2025-01-15],
      ...>   amount: -5000,
      ...>   account_id: 1,
      ...>   workspace_id: 1,
      ...>   memo: "Target shopping",
      ...>   payee_id: 2,
      ...>   lines: [
      ...>     %{amount: -3000, envelope_id: 3, memo: "Groceries"},
      ...>     %{amount: -2000, envelope_id: 4, memo: "Household items"}
      ...>   ]
      ...> })
      {:ok, %Transaction{transaction_lines: [%TransactionLine{}, %TransactionLine{}]}}

      # Ready to Assign line (envelope_id: nil)
      iex> create(%{
      ...>   date: ~D[2025-01-15],
      ...>   amount: 10000,
      ...>   account_id: 1,
      ...>   workspace_id: 1,
      ...>   memo: "Salary",
      ...>   lines: [
      ...>     %{amount: 10000, envelope_id: nil}
      ...>   ]
      ...> })
      {:ok, %Transaction{transaction_lines: [%TransactionLine{envelope_id: nil}]}}

  """
  @spec create(create_attrs(), create_options()) :: {:ok, Transaction.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs, opts \\ []) do
    Repo.transaction(fn ->
      with {:ok, transaction} <- create_transaction(attrs),
           {:ok, _lines} <- create_transaction_lines(transaction.id, attrs.lines) do
        preload_transaction(transaction, opts)
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Gets a transaction by external ID.

  ## Options

  * `:preload` - List of associations to preload. Defaults to `[]`.

  ## Examples

      iex> get_by_external_id("transaction-uuid")
      %Transaction{}

      iex> get_by_external_id("transaction-uuid", preload: [:account])
      %Transaction{account: %Account{}}

      iex> get_by_external_id("invalid-uuid")
      nil

  """
  @spec get_by_external_id(String.t(), get_options()) :: Transaction.t() | nil
  def get_by_external_id(external_id, opts \\ []) do
    external_id
    |> TransactionQuery.by_external_id()
    |> Repo.one()
    |> Utilities.maybe_preload(opts)
  end

  @doc """
  Lists all transactions for a workspace.

  ## Options

  * `:preload` - List of associations to preload. Defaults to `[]`.
  * `:limit` - Maximum number of results to return. No default limit.

  ## Examples

      iex> list_by_workspace(1)
      [%Transaction{}, %Transaction{}]

      iex> list_by_workspace(1, preload: [:account])
      [%Transaction{account: %Account{}}, %Transaction{account: %Account{}}]

      iex> list_by_workspace(1, limit: 5)
      [%Transaction{}, %Transaction{}]

  """
  @spec list_by_workspace(integer(), list_options()) :: list(Transaction.t())
  def list_by_workspace(workspace_id, opts \\ []) do
    workspace_id
    |> TransactionQuery.by_workspace_id()
    |> TransactionQuery.order_by_date()
    |> maybe_limit(opts)
    |> Repo.all()
    |> Utilities.maybe_preload(opts)
  end

  defp create_transaction(attrs) do
    transaction_attrs = Map.delete(attrs, :lines)

    %Transaction{}
    |> Transaction.changeset(transaction_attrs)
    |> Repo.insert()
  end

  defp create_transaction_lines(transaction_id, lines_attrs) do
    lines_with_transaction_id =
      Enum.map(lines_attrs, &Map.put(&1, :transaction_id, transaction_id))

    results =
      Enum.map(lines_with_transaction_id, fn line_attrs ->
        %TransactionLine{}
        |> TransactionLine.changeset(line_attrs)
        |> Repo.insert()
      end)

    case Enum.find(results, &match?({:error, _}, &1)) do
      nil -> {:ok, Enum.map(results, fn {:ok, line} -> line end)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp preload_transaction(transaction, opts) do
    preload_associations = Keyword.get(opts, :preload, [:transaction_lines])

    Repo.preload(transaction, preload_associations)
  end

  defp maybe_limit(query, opts) do
    case Keyword.get(opts, :limit) do
      nil -> query
      count -> TransactionQuery.limit(query, count)
    end
  end
end
