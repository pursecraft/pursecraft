defmodule PurseCraft.BudgetingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PurseCraft.Budgeting` context.
  """

  @doc """
  Generate a book.
  """
  def book_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "some name"
      })

    {:ok, book} = PurseCraft.Budgeting.create_book(scope, attrs)
    book
  end
end
