defmodule PurseCraft.Budgeting.Schemas.Book do
  @moduledoc """
  `Book` is the top-most level resource for Budgeting. This is where all
  resources related to budgeting are grouped under.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "books" do
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
