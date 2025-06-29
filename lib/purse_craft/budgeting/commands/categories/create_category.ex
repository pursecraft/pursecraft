defmodule PurseCraft.Budgeting.Commands.Categories.CreateCategory do
  @moduledoc """
  Creates a category and associates it with the given `Workspace`.
  """

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.CategoryRepository
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub
  alias PurseCraft.Utilities
  alias PurseCraft.Utilities.FractionalIndexing

  @type create_attrs :: %{
          optional(:name) => String.t()
        }

  @doc """
  Creates a category and associates it with the given `Workspace`.

  ## Examples

      iex> call(authorized_scope, workspace, %{name: "Monthly Bills"})
      {:ok, %Category{}}

      iex> call(authorized_scope, workspace, %{name: ""})
      {:error, %Ecto.Changeset{}}

      iex> call(unauthorized_scope, workspace, %{name: "Monthly Bills"})
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Workspace.t(), create_attrs()) ::
          {:ok, Category.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized} | {:error, :cannot_place_at_top}
  def call(%Scope{} = scope, %Workspace{} = workspace, attrs \\ %{}) do
    with :ok <- Policy.authorize(:category_create, scope, %{workspace: workspace}),
         first_position = CategoryRepository.get_first_position(workspace.id),
         {:ok, position} <- generate_top_position(first_position),
         attrs = build_attrs(attrs, workspace.id, position),
         {:ok, category} <- CategoryRepository.create(attrs) do
      PubSub.broadcast_workspace(workspace, {:category_created, category})
      {:ok, category}
    end
  end

  defp generate_top_position(first_position) do
    case FractionalIndexing.between(nil, first_position) do
      {:ok, position} -> {:ok, position}
      {:error, :cannot_go_before_a} -> {:error, :cannot_place_at_top}
    end
  end

  defp build_attrs(attrs, workspace_id, position) do
    attrs
    |> Utilities.atomize_keys()
    |> Map.put(:workspace_id, workspace_id)
    |> Map.put(:position, position)
  end
end
