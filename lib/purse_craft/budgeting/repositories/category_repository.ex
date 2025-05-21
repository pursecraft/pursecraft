defmodule PurseCraft.Budgeting.Repositories.CategoryRepository do
  @moduledoc """
  Repository for `Category`.
  """

  alias PurseCraft.Budgeting.Schemas.Category
  alias PurseCraft.Repo

  @type create_attrs :: %{
          optional(:name) => String.t(),
          required(:book_id) => integer()
        }

  @doc """
  Creates a category for a book.

  ## Examples

      iex> create(%{name: "Monthly Bills", book_id: 1})
      {:ok, %Category{}}

      iex> create(%{name: "", book_id: 1})
      {:error, %Ecto.Changeset{}}

  """
  @spec create(create_attrs()) :: {:ok, Category.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end
end
