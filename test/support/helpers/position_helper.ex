defmodule PurseCraft.TestHelpers.PositionHelper do
  @moduledoc """
  Test helpers for generating fractional positions used in drag-and-drop ordering.

  Provides consistent position generation logic across all factories that need
  fractional positioning (categories, envelopes, accounts).

  Uses the actual FractionalIndexing module to ensure generated positions follow
  the correct business logic and can be properly ordered lexicographically.
  """

  alias PurseCraft.Utilities.FractionalIndexing

  @doc """
  Generates a unique fractional position for async tests.

  Uses `System.unique_integer/1` to generate a globally unique integer,
  converts it to a valid fractional position, then uses `FractionalIndexing.between/2`
  to generate the next position after it. This ensures:

  - Positions follow the actual fractional indexing algorithm
  - Uniqueness across async tests
  - Proper lexicographic ordering
  - Tests use real business logic

  ## Examples

      iex> pos = PositionHelper.generate_lowercase_position()
      iex> FractionalIndexing.valid_position?(pos)
      true

  """
  @spec generate_lowercase_position() :: String.t()
  def generate_lowercase_position do
    n = System.unique_integer([:positive, :monotonic])

    # Convert the unique integer to a valid fractional position
    prev_position = integer_to_fractional_position(n)

    # Use FractionalIndexing to generate the next position after it
    {:ok, position} = FractionalIndexing.between(prev_position, nil)
    position
  end

  # Convert a positive integer to a valid fractional position string
  # using lowercase letters only. This creates a "previous" position
  # that we can then use with FractionalIndexing.between/2
  defp integer_to_fractional_position(n) when n > 0 do
    # Convert to base-26 using lowercase letters (a-z)
    # Start from 'a' (position 0) to 'z' (position 25)
    do_convert(n, [])
  end

  defp do_convert(0, []), do: "a"
  defp do_convert(0, acc), do: List.to_string(acc)

  defp do_convert(n, acc) do
    # Use modulo to get 0-25, then convert to 'a'-'z'
    remainder = rem(n, 26)
    char = ?a + remainder
    do_convert(div(n, 26), [char | acc])
  end
end
