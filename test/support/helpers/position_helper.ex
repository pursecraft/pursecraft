defmodule PurseCraft.TestHelpers.PositionHelper do
  @moduledoc """
  Test helpers for generating fractional positions used in drag-and-drop ordering.
  
  Provides consistent position generation logic across all factories that need
  fractional positioning (categories, envelopes, accounts).
  """

  @doc """
  Generates lowercase letter positions for fractional indexing.
  
  Starts with "m" as the middle position, then alternates between positions
  before and after "m" to create a balanced distribution.
  
  ## Examples
  
      iex> PositionHelper.generate_lowercase_position(1)
      "m"
      
      iex> PositionHelper.generate_lowercase_position(2)
      "l"
      
      iex> PositionHelper.generate_lowercase_position(3)
      "n"
  
  """
  @spec generate_lowercase_position(pos_integer()) :: String.t()
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