defmodule PurseCraft.Budgeting.Commands.Categories.ChangeCategory do
  @moduledoc """
  Returns a changeset for tracking category changes.
  """

  alias PurseCraft.Budgeting.Schemas.Category

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> call(category)
      %Ecto.Changeset{data: %Category{}}

      iex> call(category, %{name: "New Name"})
      %Ecto.Changeset{data: %Category{}, changes: %{name: "New Name"}}

  """
  @spec call(Category.t(), map()) :: Ecto.Changeset.t()
  def call(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end
end
