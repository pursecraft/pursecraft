defmodule PurseCraft.Accounting.Commands.Accounts.RepositionAccount do
  @moduledoc """
  Repositions an account between two other accounts using fractional indexing.
  """

  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.AccountRepository
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub
  alias PurseCraft.Repo
  alias PurseCraft.Utilities
  alias PurseCraft.Utilities.FractionalIndexing

  @max_retries 3

  @doc """
  Repositions an account between two other accounts.

  Takes the account's external ID and optionally the external IDs of the
  previous and next accounts. If prev_account_id is nil, the account
  will be positioned before all others. If next_account_id is nil, the
  account will be positioned after all others.

  ## Examples

      iex> call(scope, "acc-123", nil, "acc-456")
      {:ok, %Account{position: "g"}}
      
      iex> call(scope, "acc-123", "acc-456", nil)
      {:ok, %Account{position: "s"}}
      
      iex> call(scope, "acc-123", "acc-456", "acc-789")
      {:ok, %Account{position: "m"}}
      
      iex> call(unauthorized_scope, "acc-123", nil, nil)
      {:error, :unauthorized}
      
  """
  @spec call(Scope.t(), Ecto.UUID.t(), Ecto.UUID.t() | nil, Ecto.UUID.t() | nil) ::
          {:ok, Account.t()} | {:error, atom() | Ecto.Changeset.t()}
  def call(%Scope{} = scope, account_id, prev_account_id, next_account_id) do
    accounts_map =
      [account_id, prev_account_id, next_account_id]
      |> Enum.filter(&(&1 != nil))
      |> Enum.uniq()
      |> AccountRepository.list_by_external_ids(preload: [:workspace])
      |> Map.new(&{&1.external_id, &1})

    with {:ok, [account, prev_account, next_account]} <-
           validate_and_extract_accounts(
             accounts_map,
             account_id,
             prev_account_id,
             next_account_id
           ),
         :ok <- Policy.authorize(:account_update, scope, %{workspace: account.workspace}) do
      result =
        Repo.transaction(fn ->
          case attempt_reposition(account, prev_account, next_account, @max_retries) do
            {:ok, updated} -> updated
            {:error, reason} -> Repo.rollback(reason)
          end
        end)

      case result do
        {:ok, updated} ->
          PubSub.broadcast_workspace(account.workspace, {:account_repositioned, updated})
          {:ok, updated}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp validate_and_extract_accounts(accounts_map, account_id, prev_account_id, next_account_id) do
    with {:ok, account} <-
           accounts_map
           |> Map.get(account_id)
           |> Utilities.to_result(),
         {:ok, prev_account} <- validate_optional_account(accounts_map, prev_account_id, account.workspace_id),
         {:ok, next_account} <- validate_optional_account(accounts_map, next_account_id, account.workspace_id) do
      {:ok, [account, prev_account, next_account]}
    end
  end

  defp validate_optional_account(_accounts_map, nil, _workspace_id), do: {:ok, nil}

  defp validate_optional_account(accounts_map, account_id, workspace_id) do
    case Map.get(accounts_map, account_id) do
      nil ->
        {:error, :not_found}

      account ->
        if account.workspace_id == workspace_id do
          {:ok, account}
        else
          {:error, :not_found}
        end
    end
  end

  defp attempt_reposition(account, prev_account, next_account, retries_left) do
    prev_position = if prev_account, do: prev_account.position
    next_position = if next_account, do: next_account.position

    case FractionalIndexing.between(prev_position, next_position) do
      {:ok, new_position} ->
        handle_position_update(account, prev_account, next_account, new_position, retries_left)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp handle_position_update(account, prev_account, next_account, new_position, retries_left) do
    case AccountRepository.update_position(account, new_position) do
      {:ok, updated} ->
        {:ok, updated}

      {:error, changeset} ->
        if retries_left > 0 && has_unique_constraint_error?(changeset) do
          retry_with_modified_position(account, prev_account, next_account, new_position, retries_left)
        else
          {:error, changeset}
        end
    end
  end

  defp retry_with_modified_position(account, prev_account, next_account, new_position, retries_left) do
    suffix = Enum.random(["a", "m", "z"])
    new_position_with_suffix = new_position <> suffix

    modified_next =
      if next_account do
        %{next_account | position: new_position_with_suffix}
      else
        # coveralls-ignore-next-line
        %Account{position: new_position_with_suffix}
      end

    attempt_reposition(account, prev_account, modified_next, retries_left - 1)
  end

  defp has_unique_constraint_error?(changeset) do
    Enum.any?(changeset.errors, fn
      {:position, {"has already been taken", _opts}} -> true
      _error -> false
    end)
  end
end
