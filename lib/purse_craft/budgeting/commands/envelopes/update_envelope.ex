defmodule PurseCraft.Budgeting.Commands.Envelopes.UpdateEnvelope do
  @moduledoc """
  Updates an envelope with the given attributes.
  """

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.EnvelopeRepository
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub
  alias PurseCraft.Utilities

  @type attrs :: %{
          optional(:name) => String.t()
        }

  @doc """
  Updates an envelope with the given attributes.

  ## Examples

      iex> call(authorized_scope, workspace, envelope, %{name: "Updated Name"})
      {:ok, %Envelope{}}

      iex> call(authorized_scope, workspace, envelope, %{name: ""})
      {:error, %Ecto.Changeset{}}

      iex> call(unauthorized_scope, workspace, envelope, %{name: "Updated Name"})
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Workspace.t(), Envelope.t(), attrs()) ::
          {:ok, Envelope.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def call(%Scope{} = scope, %Workspace{} = workspace, %Envelope{} = envelope, attrs) do
    attrs = Utilities.atomize_keys(attrs)

    with :ok <- Policy.authorize(:envelope_update, scope, %{workspace: workspace}),
         {:ok, envelope} <- EnvelopeRepository.update(envelope, attrs) do
      PubSub.broadcast_workspace(workspace, {:envelope_updated, envelope})
      {:ok, envelope}
    end
  end
end
