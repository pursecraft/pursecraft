defmodule PurseCraft.Accounting.Repositories.TransactionRepository do
  @moduledoc """
  Repository for `Transaction`.
  """

  alias PurseCraft.Accounting.Schemas.Transaction
  alias PurseCraft.Accounting.Schemas.TransactionLine
  alias PurseCraft.Repo
  alias PurseCraft.Types

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
end
