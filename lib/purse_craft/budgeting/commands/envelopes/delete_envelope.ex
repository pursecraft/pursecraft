defmodule PurseCraft.Budgeting.Commands.Envelopes.DeleteEnvelope do
  @moduledoc """
  Deletes an envelope.
  """

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.EnvelopeRepository
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub

  @doc """
  Deletes an envelope.

  ## Examples

      iex> call(authorized_scope, workspace, envelope)
      {:ok, %Envelope{}}

      iex> call(unauthorized_scope, workspace, envelope)
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Workspace.t(), Envelope.t()) ::
          {:ok, Envelope.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def call(%Scope{} = scope, %Workspace{} = workspace, %Envelope{} = envelope) do
    with :ok <- Policy.authorize(:envelope_delete, scope, %{workspace: workspace}),
         {:ok, %Envelope{} = envelope} <- EnvelopeRepository.delete(envelope) do
      PubSub.broadcast_workspace(workspace, {:envelope_deleted, envelope})
      {:ok, envelope}
    end
  end
end
