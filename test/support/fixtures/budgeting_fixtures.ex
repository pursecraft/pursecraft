defmodule PurseCraft.BudgetingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PurseCraft.Budgeting` context.
  """

  @doc """
  Generate a book.
  """
  def book_fixture(attrs \\ %{}) do
    {:ok, book} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> PurseCraft.Budgeting.create_book()

    book
  end
end
