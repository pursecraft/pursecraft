defmodule PurseCraft.Budgeting.Commands.Envelopes.CreateEnvelope do
  @moduledoc """
  Creates an envelope and associates it with the given `Category`.
  """

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.EnvelopeRepository
  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub
  alias PurseCraft.Utilities
  alias PurseCraft.Utilities.FractionalIndexing

  @type attrs :: %{
          optional(:name) => String.t()
        }

  @doc """
  Creates an envelope and associates it with the given `Category`.

  ## Examples

      iex> call(authorized_scope, workspace, category, %{name: "Groceries"})
      {:ok, %Envelope{}}

      iex> call(authorized_scope, workspace, category, %{name: ""})
      {:error, %Ecto.Changeset{}}

      iex> call(unauthorized_scope, workspace, category, %{name: "Groceries"})
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Workspace.t(), Category.t(), attrs()) ::
          {:ok, Envelope.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized} | {:error, :cannot_place_at_top}
  def call(%Scope{} = scope, %Workspace{} = workspace, %Category{} = category, attrs \\ %{}) do
    with :ok <- Policy.authorize(:envelope_create, scope, %{workspace: workspace}),
         first_position = EnvelopeRepository.get_first_position(category.id),
         {:ok, position} <- generate_top_position(first_position),
         attrs = build_attrs(attrs, category.id, position),
         {:ok, envelope} <- EnvelopeRepository.create(attrs) do
      PubSub.broadcast_workspace(workspace, {:envelope_created, envelope})
      {:ok, envelope}
    end
  end

  defp generate_top_position(first_position) do
    case FractionalIndexing.between(nil, first_position) do
      {:ok, position} -> {:ok, position}
      {:error, :cannot_go_before_a} -> {:error, :cannot_place_at_top}
    end
  end

  defp build_attrs(attrs, category_id, position) do
    attrs
    |> Utilities.atomize_keys()
    |> Map.put(:category_id, category_id)
    |> Map.put(:position, position)
  end
end
