defmodule PurseCraft.Identity.ReadModels.User do
  @moduledoc """
  Read model for User aggregate.
  Populated by projections from User events.
  """
  use Ecto.Schema

  @primary_key {:id, Ecto.UUID, autogenerate: false}
  @foreign_key_type Ecto.UUID

  schema "users" do
    field :email, :string
    field :hashed_password, :string
    field :confirmed_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end
end
