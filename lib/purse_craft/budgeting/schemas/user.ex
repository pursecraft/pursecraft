defmodule PurseCraft.Budgeting.Schemas.User do
  @moduledoc """
  A `User` within the `Budgeting` context.
  """

  use Ecto.Schema

  @type t :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          email: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "users" do
    field :email, :string

    timestamps(type: :utc_datetime)
  end
end
