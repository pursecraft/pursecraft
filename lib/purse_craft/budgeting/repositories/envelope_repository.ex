defmodule PurseCraft.Budgeting.Repositories.EnvelopeRepository do
  @moduledoc """
  Repository for `Envelope`.
  """

  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.Repo

  @type create_attrs :: %{
          optional(:name) => String.t(),
          required(:category_id) => integer()
        }

  @doc """
  Creates an envelope for a category.

  ## Examples

      iex> create(%{name: "Groceries", category_id: 1})
      {:ok, %Envelope{}}

      iex> create(%{name: "", category_id: 1})
      {:error, %Ecto.Changeset{}}

  """
  @spec create(create_attrs()) :: {:ok, Envelope.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Envelope{}
    |> Envelope.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes an envelope.

  ## Examples

      iex> delete(%Envelope{})
      {:ok, %Envelope{}}

  """
  @spec delete(Envelope.t()) :: {:ok, Envelope.t()} | {:error, Ecto.Changeset.t()}
  def delete(%Envelope{} = envelope) do
    Repo.delete(envelope)
  end
end
