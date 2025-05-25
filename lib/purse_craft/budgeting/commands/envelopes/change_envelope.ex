defmodule PurseCraft.Budgeting.Commands.Envelopes.ChangeEnvelope do
  @moduledoc """
  Returns a changeset for tracking envelope changes.
  """

  alias PurseCraft.Budgeting.Schemas.Envelope

  @type attrs :: %{
          optional(:name) => String.t(),
          optional(:category_id) => integer()
        }

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking envelope changes.

  ## Examples

      iex> call(envelope)
      %Ecto.Changeset{data: %Envelope{}}

      iex> call(envelope, %{name: "New Name"})
      %Ecto.Changeset{data: %Envelope{}, changes: %{name: "New Name"}}

  """
  @spec call(Envelope.t(), attrs()) :: Ecto.Changeset.t()
  def call(%Envelope{} = envelope, attrs \\ %{}) do
    Envelope.changeset(envelope, attrs)
  end
end
