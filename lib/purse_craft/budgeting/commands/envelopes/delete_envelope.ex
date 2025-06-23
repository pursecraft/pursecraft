defmodule PurseCraft.Budgeting.Commands.Envelopes.DeleteEnvelope do
  @moduledoc """
  Deletes an envelope.
  """

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.EnvelopeRepository
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.Core.Schemas.Book
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub

  @doc """
  Deletes an envelope.

  ## Examples

      iex> call(authorized_scope, book, envelope)
      {:ok, %Envelope{}}

      iex> call(unauthorized_scope, book, envelope)
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Book.t(), Envelope.t()) ::
          {:ok, Envelope.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def call(%Scope{} = scope, %Book{} = book, %Envelope{} = envelope) do
    with :ok <- Policy.authorize(:envelope_delete, scope, %{book: book}),
         {:ok, %Envelope{} = envelope} <- EnvelopeRepository.delete(envelope) do
      PubSub.broadcast_book(book, {:envelope_deleted, envelope})
      {:ok, envelope}
    end
  end
end
