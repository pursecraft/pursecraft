defmodule PurseCraft.Accounting.Commands.Payees.CreatePayee do
  @moduledoc """
  Creates a payee and associates it with the given `Workspace`.
  """

  alias PurseCraft.Accounting.Policy
  alias PurseCraft.Accounting.Repositories.PayeeRepository
  alias PurseCraft.Accounting.Schemas.Payee
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub
  alias PurseCraft.Search.Workers.GenerateTokensWorker
  alias PurseCraft.Utilities

  @type create_attrs :: %{
          optional(:name) => String.t()
        }

  @doc """
  Creates a payee and associates it with the given `Workspace`.

  ## Examples

      iex> CreatePayee.call(authorized_scope, workspace, %{name: "Grocery Store"})
      {:ok, %Payee{}}

      iex> CreatePayee.call(authorized_scope, workspace, %{name: ""})
      {:error, %Ecto.Changeset{}}

      iex> CreatePayee.call(unauthorized_scope, workspace, %{name: "Grocery Store"})
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Workspace.t(), create_attrs()) ::
          {:ok, Payee.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def call(%Scope{} = scope, %Workspace{} = workspace, attrs \\ %{}) do
    with :ok <- Policy.authorize(:payee_create, scope, %{workspace: workspace}),
         attrs = build_attrs(attrs, workspace.id),
         {:ok, payee} <- PayeeRepository.create(attrs) do
      schedule_search_token_generation(payee, workspace)
      PubSub.broadcast_workspace(workspace, {:payee_created, payee})
      {:ok, payee}
    end
  end

  defp build_attrs(attrs, workspace_id) do
    attrs
    |> Utilities.atomize_keys()
    |> Map.put(:workspace_id, workspace_id)
  end

  defp schedule_search_token_generation(payee, workspace) do
    searchable_fields = Utilities.build_searchable_fields(payee, [:name])

    if map_size(searchable_fields) > 0 do
      %{
        "workspace_id" => workspace.id,
        "entity_type" => "payee",
        "entity_id" => payee.id,
        "searchable_fields" => searchable_fields
      }
      |> GenerateTokensWorker.new()
      |> Oban.insert()
    end
  end
end
