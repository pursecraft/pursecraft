defmodule PurseCraft.Accounting.Repositories.AccountRepository do
  @moduledoc """
  Repository for `Account`.
  """

  alias PurseCraft.Accounting.Queries.AccountQuery
  alias PurseCraft.Accounting.Schemas.Account
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Repo
  alias PurseCraft.Types
  alias PurseCraft.Utilities

  @type create_attrs :: %{
          optional(:name) => String.t(),
          optional(:account_type) => String.t(),
          optional(:description) => String.t(),
          required(:workspace_id) => integer(),
          required(:position) => String.t()
        }

  @type get_option :: {:preload, Types.preload()} | {:active_only, boolean()}
  @type get_options :: [get_option()]

  @type list_option :: {:preload, Types.preload()} | {:active_only, boolean()}
  @type list_options :: [list_option()]

  @type update_attrs :: %{
          optional(:name) => String.t(),
          optional(:description) => String.t()
        }

  @doc """
  Creates an account for a workspace.

  ## Examples

      iex> create(%{name: "Checking Account", account_type: "checking", workspace_id: 1, position: "m"})
      {:ok, %Account{}}

      iex> create(%{name: "", account_type: "invalid", workspace_id: 1, position: "m"})
      {:error, %Ecto.Changeset{}}

  """
  @spec create(create_attrs()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Account{}
    |> Account.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an account.

  ## Examples

      iex> update(account, %{name: "New Name"})
      {:ok, %Account{}}

      iex> update(account, %{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  @spec update(Account.t(), update_attrs()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def update(%Account{} = account, attrs) do
    account
    |> Account.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an account (hard delete).

  ## Examples

      iex> delete(account)
      {:ok, %Account{}}

      iex> delete(stale_account)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete(Account.t()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def delete(%Account{} = account) do
    Repo.delete(account, stale_error_field: :id)
  end

  @doc """
  Closes an account by setting the closed_at timestamp.

  ## Examples

      iex> close(account)
      {:ok, %Account{closed_at: ~U[2024-01-01 00:00:00Z]}}

      iex> close(already_closed_account)
      {:error, %Ecto.Changeset{}}

  """
  @spec close(Account.t()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def close(%Account{} = account) do
    account
    |> Account.close_changeset(%{closed_at: DateTime.utc_now()})
    |> Repo.update()
  end

  @doc """
  Gets the position of the first account in a workspace (ordered by position).

  Returns the position as a string, or nil if no accounts exist.

  ## Examples

      iex> get_first_position(1)
      "g"

      iex> get_first_position(999)
      nil

  """
  @spec get_first_position(integer()) :: String.t() | nil
  def get_first_position(workspace_id) do
    workspace_id
    |> AccountQuery.by_workspace_id()
    |> AccountQuery.order_by_position()
    |> AccountQuery.limit(1)
    |> AccountQuery.select_position()
    |> Repo.one()
  end

  @doc """
  Gets an account by ID within a workspace.

  ## Options

  * `:preload` - List of associations to preload. Defaults to `[]`.
  * `:active_only` - Whether to only return active accounts (not closed). Defaults to `true`.

  ## Examples

      iex> get_by_id(workspace, 123)
      %Account{}

      iex> get_by_id(workspace, 123, preload: [:workspace])
      %Account{workspace: %Workspace{}}

      iex> get_by_id(workspace, 123, active_only: false)
      %Account{}

      iex> get_by_id(workspace, 999)
      nil

      iex> get_by_id(other_workspace, 123)
      nil

  """
  @spec get_by_id(Workspace.t(), integer(), get_options()) :: Account.t() | nil
  def get_by_id(%Workspace{id: workspace_id}, id, opts \\ []) do
    id
    |> AccountQuery.by_id()
    |> AccountQuery.by_workspace_id(workspace_id)
    |> maybe_active_only(opts)
    |> Repo.one()
    |> Utilities.maybe_preload(opts)
  end

  @doc """
  Gets an account by external ID within a workspace.

  ## Options

  * `:preload` - List of associations to preload. Defaults to `[]`.
  * `:active_only` - Whether to only return active accounts (not closed). Defaults to `true`.

  ## Examples

      iex> get_by_external_id(workspace, "account-uuid")
      %Account{}

      iex> get_by_external_id(workspace, "account-uuid", preload: [:workspace])
      %Account{workspace: %Workspace{}}

      iex> get_by_external_id(workspace, "account-uuid", active_only: false)
      %Account{}

      iex> get_by_external_id(workspace, "invalid-uuid")
      nil

      iex> get_by_external_id(other_workspace, "account-uuid")
      nil

  """
  @spec get_by_external_id(Workspace.t(), String.t(), get_options()) :: Account.t() | nil
  def get_by_external_id(%Workspace{id: workspace_id}, external_id, opts \\ []) do
    external_id
    |> AccountQuery.by_external_id()
    |> AccountQuery.by_workspace_id(workspace_id)
    |> maybe_active_only(opts)
    |> Repo.one()
    |> Utilities.maybe_preload(opts)
  end

  @doc """
  Lists all accounts for a workspace.

  ## Options

  * `:preload` - List of associations to preload. Defaults to `[]`.
  * `:active_only` - Whether to only return active accounts (not closed). Defaults to `true`.

  ## Examples

      iex> list_by_workspace(1)
      [%Account{}, %Account{}]

      iex> list_by_workspace(1, preload: [:workspace])
      [%Account{workspace: %Workspace{}}, %Account{workspace: %Workspace{}}]

      iex> list_by_workspace(1, active_only: false)
      [%Account{}, %Account{closed_at: ~U[2024-01-01 00:00:00Z]}]

      iex> list_by_workspace(999)
      []

  """
  @spec list_by_workspace(integer(), list_options()) :: list(Account.t())
  def list_by_workspace(workspace_id, opts \\ []) do
    workspace_id
    |> AccountQuery.by_workspace_id()
    |> maybe_active_only(opts)
    |> AccountQuery.order_by_position()
    |> Repo.all()
    |> Utilities.maybe_preload(opts)
  end

  @doc """
  Updates the position of an account.

  ## Examples

      iex> update_position(account, "m")
      {:ok, %Account{position: "m"}}

      iex> update_position(account, "ABC")
      {:error, %Ecto.Changeset{}}

  """
  @spec update_position(Account.t(), String.t()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def update_position(account, new_position) do
    account
    |> Account.position_changeset(%{position: new_position})
    |> Repo.update()
  end

  @doc """
  Gets multiple accounts by external IDs.

  ## Options

  The `:preload` option accepts a list of associations to preload.

  ## Examples

      iex> list_by_external_ids(["id1", "id2", "id3"])
      [%Account{}, %Account{}]

      iex> list_by_external_ids(["id1", "id2"], preload: [:workspace])
      [%Account{workspace: %Workspace{}}, %Account{workspace: %Workspace{}}]

  """
  @spec list_by_external_ids([Ecto.UUID.t()], list_options()) :: list(Account.t())
  def list_by_external_ids(external_ids, opts \\ []) when is_list(external_ids) do
    external_ids
    |> AccountQuery.by_external_ids()
    |> Repo.all()
    |> Utilities.maybe_preload(opts)
  end

  defp maybe_active_only(query, opts) do
    if Keyword.get(opts, :active_only, true) do
      AccountQuery.active(query)
    else
      query
    end
  end
end
