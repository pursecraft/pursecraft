defmodule PurseCraft.Accounting do
  @moduledoc """
  The Accounting context.
  """

  alias PurseCraft.Accounting.Commands.Accounts.CloseAccount
  alias PurseCraft.Accounting.Commands.Accounts.CreateAccount
  alias PurseCraft.Accounting.Commands.Accounts.DeleteAccount
  alias PurseCraft.Accounting.Commands.Accounts.FetchAccount
  alias PurseCraft.Accounting.Commands.Accounts.FetchAccountByExternalId
  alias PurseCraft.Accounting.Commands.Accounts.ListAccounts
  alias PurseCraft.Accounting.Commands.Accounts.RepositionAccount
  alias PurseCraft.Accounting.Commands.Accounts.UpdateAccount
  alias PurseCraft.Accounting.Commands.Payees.CleanupOrphanedPayees
  alias PurseCraft.Accounting.Commands.Payees.CreatePayee
  alias PurseCraft.Accounting.Commands.Payees.FindOrCreatePayee
  alias PurseCraft.Accounting.Commands.Transactions.CreateTransaction
  alias PurseCraft.Accounting.Commands.Transactions.CreateTransfer
  alias PurseCraft.Accounting.Commands.Transactions.DeleteTransaction
  alias PurseCraft.Accounting.Commands.Transactions.UpdateTransaction
  alias PurseCraft.Accounting.Commands.Transactions.UpdateTransfer

  @doc """
  Creates an account and associates it with the given `Workspace`.

  ## Examples

      iex> create_account(scope, workspace, %{name: "Checking Account", account_type: "checking"})
      {:ok, %Account{}}

      iex> create_account(scope, workspace, %{name: "", account_type: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  # coveralls-ignore-next-line
  defdelegate create_account(scope, workspace, attrs \\ %{}), to: CreateAccount, as: :call

  @doc """
  Fetches an account by external ID.

  ## Examples

      iex> fetch_account_by_external_id(scope, workspace, "account-uuid")
      {:ok, %Account{}}

      iex> fetch_account_by_external_id(scope, workspace, "invalid-uuid")
      {:error, :not_found}

  """
  # coveralls-ignore-next-line
  defdelegate fetch_account(scope, workspace, id_or_struct, opts \\ []),
    to: FetchAccount,
    as: :call

  # coveralls-ignore-next-line
  defdelegate fetch_account_by_external_id(scope, workspace, external_id, opts \\ []),
    to: FetchAccountByExternalId,
    as: :call

  @doc """
  Lists all accounts for a workspace.

  ## Examples

      iex> list_accounts(scope, workspace)
      [%Account{}, %Account{}]

      iex> list_accounts(scope, workspace, preload: [:workspace])
      [%Account{workspace: %Workspace{}}, %Account{workspace: %Workspace{}}]

  """
  # coveralls-ignore-next-line
  defdelegate list_accounts(scope, workspace, opts \\ []), to: ListAccounts, as: :call

  @doc """
  Updates an account for a workspace.

  ## Examples

      iex> update_account(scope, workspace, "account-uuid", %{name: "New Name"})
      {:ok, %Account{}}

      iex> update_account(scope, workspace, "account-uuid", %{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  # coveralls-ignore-next-line
  defdelegate update_account(scope, workspace, external_id, attrs), to: UpdateAccount, as: :call

  @doc """
  Deletes an account for a workspace.

  ## Examples

      iex> delete_account(scope, workspace, "account-uuid")
      {:ok, %Account{}}

      iex> delete_account(scope, workspace, "invalid-uuid")
      {:error, :not_found}

  """
  # coveralls-ignore-next-line
  defdelegate delete_account(scope, workspace, external_id), to: DeleteAccount, as: :call

  @doc """
  Closes an account for a workspace by setting the closed_at timestamp.

  ## Examples

      iex> close_account(scope, workspace, "account-uuid")
      {:ok, %Account{closed_at: ~U[2024-01-01 00:00:00Z]}}

      iex> close_account(scope, workspace, "invalid-uuid")
      {:error, :not_found}

  """
  # coveralls-ignore-next-line
  defdelegate close_account(scope, workspace, external_id), to: CloseAccount, as: :call

  @doc """
  Repositions an account between two other accounts using fractional indexing.

  ## Examples

      iex> reposition_account(scope, "acc-123", "acc-456", "acc-789")
      {:ok, %Account{position: "m"}}

      iex> reposition_account(scope, "acc-123", nil, "acc-456")
      {:ok, %Account{position: "g"}}

  """
  # coveralls-ignore-next-line
  defdelegate reposition_account(scope, account_id, prev_account_id, next_account_id), to: RepositionAccount, as: :call

  @doc """
  Creates a payee and associates it with the given `Workspace`.

  ## Examples

      iex> create_payee(scope, workspace, %{name: "Amazon"})
      {:ok, %Payee{}}

      iex> create_payee(scope, workspace, %{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  # coveralls-ignore-next-line
  defdelegate create_payee(scope, workspace, attrs), to: CreatePayee, as: :call

  @doc """
  Finds or creates a payee with the given name in the workspace.

  ## Examples

      iex> find_or_create_payee(scope, workspace, "Amazon")
      {:ok, %Payee{}}

  """
  # coveralls-ignore-next-line
  defdelegate find_or_create_payee(scope, workspace, payee_name), to: FindOrCreatePayee, as: :call

  @doc """
  Cleans up orphaned payees in a workspace.

  System maintenance - removes payees with no transaction references.

  ## Examples

      iex> cleanup_orphaned_payees(workspace)
      {:ok, 3}

  """
  # coveralls-ignore-next-line
  defdelegate cleanup_orphaned_payees(workspace), to: CleanupOrphanedPayees, as: :call

  @doc """
  Creates a transaction with automatic double-entry handling.

  Accepts either simple format (source + destination) or split format (source + lines).
  All amounts are positive - the command determines debit/credit based on entity types.

  ## Examples

      iex> create_transaction(scope, workspace, %{
      ...>   source: %Account{},
      ...>   destination: %Envelope{},
      ...>   with: %Payee{},
      ...>   amount: 2500,
      ...>   memo: "Groceries"
      ...> })
      {:ok, %Transaction{}}

      iex> create_transaction(scope, workspace, %{
      ...>   source: %Payee{},
      ...>   destination: %Account{},
      ...>   with: :ready_to_assign,
      ...>   amount: 300000,
      ...>   memo: "Salary"
      ...> })
      {:ok, %Transaction{}}

  """
  # coveralls-ignore-next-line
  defdelegate create_transaction(scope, workspace, attrs), to: CreateTransaction, as: :call

  @doc """
  Updates a transaction for a workspace.

  Only allows updating memo, cleared status, and transaction lines.
  Amount, date, and account changes are blocked to maintain audit trail.

  When updating lines, validates that sum(lines.amount) == transaction.amount.

  ## Examples

      iex> update_transaction(scope, workspace, "txn-uuid", %{memo: "Updated"})
      {:ok, %Transaction{}}

      iex> update_transaction(scope, workspace, "txn-uuid", %{cleared: true})
      {:ok, %Transaction{}}

      iex> update_transaction(scope, workspace, "txn-uuid", %{
      ...>   lines: [%{amount: 5000, envelope_id: 3}]
      ...> })
      {:ok, %Transaction{}}

      iex> update_transaction(scope, workspace, "invalid-uuid", %{memo: "Test"})
      {:error, :not_found}

  """
  # coveralls-ignore-next-line
  defdelegate update_transaction(scope, workspace, external_id, attrs), to: UpdateTransaction, as: :call

  @doc """
  Deletes a transaction from the workspace.

  Transaction lines are automatically cascade-deleted.
  Schedules cleanup for orphaned payees and search tokens.

  ## Examples

      iex> delete_transaction(scope, workspace, "txn-uuid")
      {:ok, %Transaction{}}

      iex> delete_transaction(scope, workspace, "invalid")
      {:error, :not_found}

      iex> delete_transaction(unauthorized_scope, workspace, "txn-uuid")
      {:error, :unauthorized}

  """
  # coveralls-ignore-next-line
  defdelegate delete_transaction(scope, workspace, external_id), to: DeleteTransaction, as: :call

  @doc """
  Creates a transfer between two accounts.

  A transfer creates two linked transactions:
  - Outflow from source account (negative amount)
  - Inflow to destination account (positive amount)

  Both transactions are linked bidirectionally and have no budget impact (envelope_id: nil).
  The operation is atomic - either both succeed or both rollback.

  ## Examples

      iex> create_transfer(scope, workspace, %{
      ...>   from_account: %Account{},
      ...>   to_account: %Account{},
      ...>   amount: 50000,
      ...>   memo: "Monthly savings"
      ...> })
      {:ok, {%Transaction{amount: -50000}, %Transaction{amount: 50000}}}

      iex> create_transfer(scope, workspace, %{
      ...>   from_account: "account-uuid-1",
      ...>   to_account: "account-uuid-2",
      ...>   amount: 25000,
      ...>   cleared: true
      ...> })
      {:ok, {%Transaction{cleared: true}, %Transaction{cleared: true}}}

  """
  # coveralls-ignore-next-line
  defdelegate create_transfer(scope, workspace, attrs), to: CreateTransfer, as: :call

  @doc """
  Updates a transfer between two accounts.

  Allows updating memo, cleared status, amount, and date. Changes to amount are
  applied to both sides with correct signs based on account types. Account and
  workspace changes are silently ignored to maintain transfer integrity.

  Both sides of the transfer are updated synchronously - either both succeed
  or both rollback. Search tokens are regenerated if memo changes, and
  PubSub events are broadcast for both transactions.

  ## Examples

      iex> update_transfer(scope, workspace, "txn-uuid", %{memo: "Updated memo"})
      {:ok, {%Transaction{memo: "Updated memo"}, %Transaction{memo: "Updated memo"}}}

      iex> update_transfer(scope, workspace, "txn-uuid", %{cleared: true})
      {:ok, {%Transaction{cleared: true}, %Transaction{cleared: true}}}

      iex> update_transfer(scope, workspace, "txn-uuid", %{amount: 50000})
      {:ok, {%Transaction{amount: -50000}, %Transaction{amount: 50000}}}

      iex> update_transfer(scope, workspace, "txn-uuid", %{date: ~D[2025-01-15]})
      {:ok, {%Transaction{date: ~D[2025-01-15]}, %Transaction{date: ~D[2025-01-15]}}}

  ## Errors

  - `{:error, :not_found}` - Transaction doesn't exist or linked transaction missing
  - `{:error, :unauthorized}` - User lacks editor/owner permission
  - `{:error, :not_a_transfer}` - Transaction is not part of a transfer

  """
  # coveralls-ignore-next-line
  defdelegate update_transfer(scope, workspace, transaction_external_id, attrs),
    to: UpdateTransfer,
    as: :call
end
