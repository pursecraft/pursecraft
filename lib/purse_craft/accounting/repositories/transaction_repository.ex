defmodule PurseCraft.Accounting.Repositories.TransactionRepository do
  @moduledoc """
  Repository for `Transaction`.
  """

  alias PurseCraft.Accounting.Queries.TransactionLineQuery
  alias PurseCraft.Accounting.Queries.TransactionQuery
  alias PurseCraft.Accounting.Schemas.Transaction
  alias PurseCraft.Accounting.Schemas.TransactionLine
  alias PurseCraft.Core.Schemas.Workspace
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

  @type update_attrs :: %{
          optional(:date) => Date.t(),
          optional(:amount) => integer(),
          optional(:memo) => String.t(),
          optional(:cleared) => boolean(),
          optional(:payee_id) => integer() | nil
        }

  @type update_with_lines_option :: {:preload, Types.preload()}
  @type update_with_lines_options :: [update_with_lines_option()]

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
  Gets a transaction by ID within a workspace.

  ## Options

  * `:preload` - List of associations to preload. Defaults to `[]`.

  ## Examples

      iex> get_by_id(workspace, 123)
      %Transaction{}

      iex> get_by_id(workspace, 123, preload: [:account])
      %Transaction{account: %Account{}}

      iex> get_by_id(workspace, 999)
      nil

      iex> get_by_id(other_workspace, 123)
      nil

  """
  @spec get_by_id(Workspace.t(), integer(), get_options()) :: Transaction.t() | nil
  def get_by_id(%Workspace{id: workspace_id}, id, opts \\ []) do
    id
    |> TransactionQuery.by_id()
    |> TransactionQuery.by_workspace_id(workspace_id)
    |> Repo.one()
    |> Utilities.maybe_preload(opts)
  end

  @doc """
  Gets a transaction by external ID within a workspace.

  ## Options

  * `:preload` - List of associations to preload. Defaults to `[]`.

  ## Examples

      iex> get_by_external_id(workspace, "transaction-uuid")
      %Transaction{}

      iex> get_by_external_id(workspace, "transaction-uuid", preload: [:account])
      %Transaction{account: %Account{}}

      iex> get_by_external_id(workspace, "invalid-uuid")
      nil

      iex> get_by_external_id(other_workspace, "transaction-uuid")
      nil

  """
  @spec get_by_external_id(Workspace.t(), String.t(), get_options()) :: Transaction.t() | nil
  def get_by_external_id(%Workspace{id: workspace_id}, external_id, opts \\ []) do
    external_id
    |> TransactionQuery.by_external_id()
    |> TransactionQuery.by_workspace_id(workspace_id)
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
    |> Utilities.maybe_limit(opts)
    |> Repo.all()
    |> Utilities.maybe_preload(opts)
  end

  @doc """
  Updates a transaction.

  Only updates the fields provided in attrs. The account_id and workspace_id
  fields are immutable and cannot be changed after creation.

  ## Examples

      iex> update(transaction, %{memo: "Updated memo"})
      {:ok, %Transaction{memo: "Updated memo"}}

      iex> update(transaction, %{cleared: true})
      {:ok, %Transaction{cleared: true}}

      iex> update(transaction, %{date: nil})
      {:error, %Ecto.Changeset{}}

  """
  @spec update(Transaction.t(), update_attrs()) :: {:ok, Transaction.t()} | {:error, Ecto.Changeset.t()}
  def update(transaction, attrs) do
    attrs = Map.drop(attrs, [:account_id, :workspace_id])

    transaction
    |> Transaction.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a transaction and its lines atomically.

  This function deletes all existing transaction lines and creates new ones
  based on the provided lines_attrs. The update is performed within a database
  transaction, ensuring atomicity - either all changes succeed or all are rolled back.

  Every transaction must have at least one line. Passing an empty lines array will result in an error.

  ## Options

  * `:preload` - List of associations to preload. Defaults to `[:transaction_lines]`.

  ## Examples

      # Update transaction and replace with single line
      iex> update_with_lines(transaction, %{amount: 5000}, [
      ...>   %{amount: 5000, envelope_id: 3}
      ...> ])
      {:ok, %Transaction{amount: 5000, transaction_lines: [%TransactionLine{}]}}

      # Update to split transaction
      iex> update_with_lines(transaction, %{amount: 7500}, [
      ...>   %{amount: 5000, envelope_id: 3, memo: "Groceries"},
      ...>   %{amount: 2500, envelope_id: 4, memo: "Gas"}
      ...> ])
      {:ok, %Transaction{transaction_lines: [%TransactionLine{}, %TransactionLine{}]}}

      # Error: empty lines
      iex> update_with_lines(transaction, %{}, [])
      {:error, %Ecto.Changeset{}}

      # With custom preload
      iex> update_with_lines(transaction, %{}, lines, preload: [:account, :transaction_lines])
      {:ok, %Transaction{account: %Account{}, transaction_lines: [...]}}

  """
  @spec update_with_lines(Transaction.t(), update_attrs(), [transaction_line_attrs()], update_with_lines_options()) ::
          {:ok, Transaction.t()} | {:error, Ecto.Changeset.t()}
  def update_with_lines(transaction, attrs, lines_attrs, opts \\ []) do
    case lines_attrs do
      [] ->
        changeset =
          transaction
          |> Ecto.Changeset.change()
          |> Ecto.Changeset.add_error(:lines, "must have at least one transaction line")

        {:error, changeset}

      _lines_present ->
        Repo.transaction(fn ->
          with {:ok, _deleted_count} <- delete_all_lines(transaction.id),
               {:ok, updated_transaction} <- update(transaction, attrs),
               {:ok, _created_lines} <- create_transaction_lines(updated_transaction.id, lines_attrs) do
            preload_associations = Keyword.get(opts, :preload, [:transaction_lines])
            Repo.preload(updated_transaction, preload_associations, force: true)
          else
            {:error, changeset} -> Repo.rollback(changeset)
          end
        end)
    end
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

  defp delete_all_lines(transaction_id) do
    transaction_id
    |> TransactionLineQuery.by_transaction_id()
    |> Repo.delete_all()
    |> case do
      {deleted_count, _nil} -> {:ok, deleted_count}
    end
  end

  defp preload_transaction(transaction, opts) do
    preload_associations = Keyword.get(opts, :preload, [:transaction_lines])

    Repo.preload(transaction, preload_associations)
  end
end
