defmodule PurseCraft.TestHelpers.PositionHelper do
  @moduledoc """
  Test helpers for generating fractional positions used in drag-and-drop ordering.

  Provides consistent position generation logic across all factories that need
  fractional positioning (categories, envelopes, accounts).
  """

  @doc """
  Generates a unique lowercase letter position for async tests.

  Uses `System.unique_integer/1` to generate a globally unique integer,
  then converts it to a fractional position. This is useful for async tests
  where factory sequences may collide within workspace-scoped uniqueness
  constraints.

  ## Examples

      iex> pos = PositionHelper.generate_lowercase_position()
      iex> is_binary(pos)
      true

  """
  @spec generate_lowercase_position() :: String.t()
  def generate_lowercase_position do
    [:positive, :monotonic]
    |> System.unique_integer()
    |> generate_lowercase_position()
  end

  @doc """
  Generates lowercase letter positions for fractional indexing based on a sequence number.

  Starts with "m" as the middle position, then alternates between positions
  before and after "m" to create a balanced distribution. This is primarily
  used by factory sequences for deterministic positioning.

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

  def generate_lowercase_position(n) when n > 26 do
    # For large numbers, generate a unique multi-character position
    # Convert to base-26 representation using lowercase letters
    integer_to_position_string(n)
  end

  defp integer_to_position_string(n) when n > 0 do
    integer_to_position_string(div(n, 26), rem(n, 26), "")
  end

  defp integer_to_position_string(0, 0, acc), do: acc

  defp integer_to_position_string(0, remainder, acc) do
    <<?a + remainder>> <> acc
  end

  defp integer_to_position_string(quotient, remainder, acc) do
    integer_to_position_string(div(quotient, 26), rem(quotient, 26), <<?a + remainder>> <> acc)
  end
end
