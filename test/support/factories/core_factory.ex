defmodule PurseCraft.CoreFactory do
  @moduledoc false

  use PurseCraft.FactoryTemplate

  alias PurseCraft.Core.Schemas.Book
  alias PurseCraft.Core.Schemas.BookUser

  def book_factory do
    name = Faker.Pokemon.name()

    book =
      %Book{}
      |> Book.changeset(%{name: name})
      |> Ecto.Changeset.apply_changes()

    book
  end

  def book_user_factory do
    %BookUser{
      role: Enum.random([:owner, :editor, :commenter])
    }
  end
end
