defmodule PurseCraft.Core.Repositories.WorkspaceRepository do
  @moduledoc """
  Repository for `Workspace`.
  """

  alias Ecto.Multi
  alias PurseCraft.Core.Queries.WorkspaceQuery
  alias PurseCraft.Core.Queries.WorkspaceUserQuery
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Core.Schemas.WorkspaceUser
  alias PurseCraft.Repo
  alias PurseCraft.Utilities

  @type preload_item :: atom() | {atom(), preload_item()} | [preload_item()]
  @type preload :: preload_item() | [preload_item()]

  @type get_workspace_option :: {:preload, preload()}
  @type get_workspace_options :: [get_workspace_option()]

  @type create_attrs :: %{
          optional(:name) => String.t()
        }

  @type update_attrs :: %{
          optional(:name) => String.t()
        }

  @doc """
  Lists all workspaces for a specific user.

  ## Examples

      iex> list_by_user(user_id)
      [%Workspace{}, ...]

  """
  @spec list_by_user(integer()) :: list(Workspace.t())
  def list_by_user(user_id) do
    user_id
    |> WorkspaceQuery.by_user()
    |> Repo.all()
  end

  @doc """
  Gets a workspace by its external ID.

  Raises `Ecto.NoResultsError` if the Workspace does not exist.

  ## Examples

      iex> get_by_external_id!("abcd-1234")
      %Workspace{}

      iex> get_by_external_id!("non-existent-id")
      ** (Ecto.NoResultsError)

  """
  @spec get_by_external_id!(Ecto.UUID.t()) :: Workspace.t()
  def get_by_external_id!(external_id) do
    external_id
    |> WorkspaceQuery.by_external_id()
    |> Repo.one!()
  end

  @doc """
  Gets a workspace by its external ID with optional preloading.

  Returns the workspace if it exists, or `nil` if not found.

  ## Options

  The `:preload` option accepts a list of associations to preload. For example:

  - `[preload: [:categories]]` - preloads only categories
  - `[preload: [categories: :envelopes]]` - preloads categories and their envelopes

  ## Examples

      iex> get_by_external_id("abcd-1234")
      %Workspace{}

      iex> get_by_external_id("abcd-1234", preload: [:categories])
      %Workspace{categories: [...]}

      iex> get_by_external_id("non-existent-id")
      nil

  """
  @spec get_by_external_id(Ecto.UUID.t(), get_workspace_options()) :: Workspace.t() | nil
  def get_by_external_id(external_id, opts \\ []) do
    external_id
    |> WorkspaceQuery.by_external_id()
    |> Repo.one()
    |> Utilities.maybe_preload(opts)
  end

  @doc """
  Creates a workspace and associates it with a user as the owner.

  ## Examples

      iex> create(%{name: "Household"}, user_id)
      {:ok, %Workspace{}}

      iex> create(%{name: ""}, user_id)
      {:error, %Ecto.Changeset{}}

  """

  @spec create(create_attrs(), integer()) :: {:ok, Workspace.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs, user_id) do
    Multi.new()
    |> Multi.insert(:workspace, Workspace.changeset(%Workspace{}, attrs))
    |> Multi.insert(:workspace_user, fn %{workspace: workspace} ->
      WorkspaceUser.changeset(%WorkspaceUser{}, %{
        workspace_id: workspace.id,
        user_id: user_id,
        role: :owner
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{workspace: workspace}} -> {:ok, workspace}
      {:error, _operations, changeset, _changes} -> {:error, changeset}
    end
  end

  @doc """
  Updates a workspace.

  ## Examples

      iex> update(%Workspace{}, %{name: "Updated Name"})
      {:ok, %Workspace{}}

      iex> update(%Workspace{}, %{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  @spec update(Workspace.t(), update_attrs()) :: {:ok, Workspace.t()} | {:error, Ecto.Changeset.t()}
  def update(%Workspace{} = workspace, attrs) do
    workspace
    |> Workspace.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a workspace and its associated WorkspaceUser records.

  ## Examples

      iex> delete(%Workspace{})
      {:ok, %Workspace{}}

      iex> delete(%Workspace{})
      {:error, %Ecto.Changeset{}}

  """
  @spec delete(Workspace.t()) :: {:ok, Workspace.t()} | {:error, Ecto.Changeset.t()}
  def delete(%Workspace{} = workspace) do
    Multi.new()
    |> Multi.delete_all(:delete_workspace_users, WorkspaceUserQuery.by_workspace_id(workspace.id))
    |> Multi.delete(:delete_workspace, workspace)
    |> Repo.transaction()
    |> case do
      {:ok, %{delete_workspace: workspace}} ->
        {:ok, workspace}

      # coveralls-ignore-start
      {:error, _operation, error, _changes} ->
        {:error, error}
        # coveralls-ignore-stop
    end
  end
end
