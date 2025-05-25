defmodule PurseCraft.Budgeting.Commands.Books.ChangeBook do
  @moduledoc """
  Returns a changeset for tracking book changes.
  """

  alias PurseCraft.Budgeting.Schemas.Book

  @type attrs :: %{
          optional(:name) => String.t()
        }

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking book changes.

  ## Examples

      iex> call(book)
      %Ecto.Changeset{data: %Book{}}

      iex> call(book, %{name: "New Name"})
      %Ecto.Changeset{data: %Book{}, changes: %{name: "New Name"}}

  """
  @spec call(Book.t(), attrs()) :: Ecto.Changeset.t()
  def call(%Book{} = book, attrs \\ %{}) do
    Book.changeset(book, attrs)
  end
end
