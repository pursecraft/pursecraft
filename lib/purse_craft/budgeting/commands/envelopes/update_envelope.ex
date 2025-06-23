defmodule PurseCraft.Budgeting.Commands.Envelopes.UpdateEnvelope do
  @moduledoc """
  Updates an envelope with the given attributes.
  """

  alias PurseCraft.Budgeting.Policy
  alias PurseCraft.Budgeting.Repositories.EnvelopeRepository
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.Core.Schemas.Book
  alias PurseCraft.Identity.Schemas.Scope
  alias PurseCraft.PubSub
  alias PurseCraft.Utilities

  @type attrs :: %{
          optional(:name) => String.t()
        }

  @doc """
  Updates an envelope with the given attributes.

  ## Examples

      iex> call(authorized_scope, book, envelope, %{name: "Updated Name"})
      {:ok, %Envelope{}}

      iex> call(authorized_scope, book, envelope, %{name: ""})
      {:error, %Ecto.Changeset{}}

      iex> call(unauthorized_scope, book, envelope, %{name: "Updated Name"})
      {:error, :unauthorized}

  """
  @spec call(Scope.t(), Book.t(), Envelope.t(), attrs()) ::
          {:ok, Envelope.t()} | {:error, Ecto.Changeset.t()} | {:error, :unauthorized}
  def call(%Scope{} = scope, %Book{} = book, %Envelope{} = envelope, attrs) do
    attrs = Utilities.atomize_keys(attrs)

    with :ok <- Policy.authorize(:envelope_update, scope, %{book: book}),
         {:ok, envelope} <- EnvelopeRepository.update(envelope, attrs) do
      PubSub.broadcast_book(book, {:envelope_updated, envelope})
      {:ok, envelope}
    end
  end
end
