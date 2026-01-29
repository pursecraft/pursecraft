defmodule PurseCraft.Identity.ReadModels.Token do
  @moduledoc """
  Read model for Token aggregate.
  Populated by projections from Token events.
  """
  use Ecto.Schema

  @primary_key {:id, Ecto.UUID, autogenerate: false}
  @foreign_key_type Ecto.UUID

  schema "new_users_tokens" do
    belongs_to :user, PurseCraft.Identity.ReadModels.User
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    field :authenticated_at, :utc_datetime

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
