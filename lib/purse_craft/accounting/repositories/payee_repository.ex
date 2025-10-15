defmodule PurseCraft.Accounting.Repositories.PayeeRepository do
  @moduledoc """
  Repository for `Payee`.
  """

  alias PurseCraft.Accounting.Queries.PayeeQuery
  alias PurseCraft.Accounting.Schemas.Payee
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Repo
  alias PurseCraft.Types
  alias PurseCraft.Utilities

  @type create_attrs :: %{
          required(:name) => String.t(),
          required(:workspace_id) => integer()
        }

  @type get_option :: {:preload, Types.preload()}
  @type get_options :: [get_option()]

  @type list_option :: {:preload, Types.preload()} | {:limit, integer()}
  @type list_options :: [list_option()]

  @doc """
  Creates a payee.

  ## Examples

      iex> create(%{name: "Grocery Store", workspace_id: 1})
      {:ok, %Payee{}}

      iex> create(%{name: "", workspace_id: 1})
      {:error, %Ecto.Changeset{}}

  """
  @spec create(create_attrs()) :: {:ok, Payee.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Payee{}
    |> Payee.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a payee.

  ## Examples

      iex> delete(payee)
      {:ok, %Payee{}}

      iex> delete(stale_payee)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete(Payee.t()) :: {:ok, Payee.t()} | {:error, Ecto.Changeset.t()}
  def delete(%Payee{} = payee) do
    Repo.delete(payee, stale_error_field: :id)
  end

  @doc """
  Gets a payee by external ID.

  ## Options

  * `:preload` - List of associations to preload. Defaults to `[]`.

  ## Examples

      iex> get_by_external_id("payee-uuid")
      %Payee{}

      iex> get_by_external_id("payee-uuid", preload: [:workspace])
      %Payee{workspace: %Workspace{}}

      iex> get_by_external_id("invalid-uuid")
      nil

  """
  @spec get_by_external_id(String.t(), get_options()) :: Payee.t() | nil
  def get_by_external_id(external_id, opts \\ []) do
    external_id
    |> PayeeQuery.by_external_id()
    |> Repo.one()
    |> Utilities.maybe_preload(opts)
  end

  @doc """
  Gets a payee by name within a workspace using the name hash for exact matching.

  ## Options

  * `:preload` - List of associations to preload. Defaults to `[]`.

  ## Examples

      iex> get_by_name(workspace, "Grocery Store")
      %Payee{}

      iex> get_by_name(workspace, "Grocery Store", preload: [:workspace])
      %Payee{workspace: %Workspace{}}

      iex> get_by_name(workspace, "Non-existent")
      nil

  """
  @spec get_by_name(Workspace.t(), String.t(), get_options()) :: Payee.t() | nil
  def get_by_name(%Workspace{id: workspace_id}, name, opts \\ []) do
    workspace_id
    |> PayeeQuery.by_workspace_id()
    |> PayeeQuery.by_name_hash(name)
    |> Repo.one()
    |> Utilities.maybe_preload(opts)
  end

  @doc """
  Lists all payees for a workspace.

  ## Options

  * `:preload` - List of associations to preload. Defaults to `[]`.
  * `:limit` - Maximum number of results to return. No default limit.

  ## Examples

      iex> list_by_workspace(workspace)
      [%Payee{}, %Payee{}]

      iex> list_by_workspace(workspace, preload: [:workspace])
      [%Payee{workspace: %Workspace{}}, %Payee{workspace: %Workspace{}}]

      iex> list_by_workspace(workspace, limit: 5)
      [%Payee{}, %Payee{}]

  """
  @spec list_by_workspace(Workspace.t(), list_options()) :: list(Payee.t())
  def list_by_workspace(%Workspace{id: workspace_id}, opts \\ []) do
    workspace_id
    |> PayeeQuery.by_workspace_id()
    |> PayeeQuery.order_by_name()
    |> Utilities.maybe_limit(opts)
    |> Repo.all()
    |> Utilities.maybe_preload(opts)
  end
end
