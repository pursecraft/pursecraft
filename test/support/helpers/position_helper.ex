defmodule PurseCraft.TestHelpers.PositionHelper do
  @moduledoc """
  Helper functions for generating fractional positioning values used in tests.
  """

  @doc """
  Generates lowercase letter-based position strings for drag-and-drop ordering.

  This function generates positions that can be sorted alphabetically to maintain
  order while allowing insertions between existing items.

  ## Examples

      iex> PositionHelper.generate_lowercase_position(1)
      "m"

      iex> PositionHelper.generate_lowercase_position(2)
      "l"

      iex> PositionHelper.generate_lowercase_position(3)
      "n"

  """
  def generate_lowercase_position(1), do: "m"

  def generate_lowercase_position(n) when n <= 26 do
    if rem(n, 2) == 1 do
      offset = div(n - 1, 2)
      char_code = ?m + offset

      if char_code <= ?z do
        <<char_code>>
      else
        "ma"
      end
    else
      offset = div(n, 2)
      char_code = ?m - offset

      if char_code >= ?a do
        <<char_code>>
      else
        "mb"
      end
    end
  end

  def generate_lowercase_position(n) do
    second_offset = rem(n - 27, 26)
    "m" <> <<?a + second_offset>>
  end
end
