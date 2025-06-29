defmodule PurseCraft.Budgeting.Commands.Envelopes.FetchEnvelopeByExternalId do
  @moduledoc """
  Fetches an envelope by external ID for a given workspace.
  """

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.EnvelopeRepository
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.Core.Schemas.Workspace
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.Types
  alias PurseCraft.Utilities

  @type option :: {:preload, Types.preload()}
  @type options :: [option()]

  @doc """
  Fetches an envelope by external ID for a given workspace.

  ## Examples

      iex> call(authorized_scope, workspace, "abcd-1234", preload: [:category])
      {:ok, %Envelope{category: %Category{}}}

      iex> call(authorized_scope, workspace, "invalid-id")
      {:error, :not_found}

      iex> call(unauthorized_scope, workspace, "abcd-1234")
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Workspace.t(), Ecto.UUID.t(), options()) ::
          {:ok, Envelope.t()} | {:error, :not_found | :unauthorized}
  def call(%Scope{} = scope, %Workspace{} = workspace, external_id, opts \\ []) do
    with :ok <- Policy.authorize(:envelope_read, scope, %{workspace: workspace}) do
      external_id
      |> EnvelopeRepository.get_by_external_id_and_workspace_id(workspace.id, opts)
      |> Utilities.to_result()
    end
  end
end
