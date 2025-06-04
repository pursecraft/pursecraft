defmodule PurseCraft.Utilities.FractionalIndexing do
  @moduledoc """
  Implements Fractional Indexing, a term coined by Figma in their blog post.
  https://www.figma.com/blog/realtime-editing-of-ordered-sequences/

  Uses lexicographic ordering where positions are strings that can be
  compared alphabetically. This allows inserting items between any two
  positions without affecting other items.

  IMPORTANT: This is a simplified implementation of Fractional Indexing.
  Specifically, there are 2 deliberate limitations because the usecase
  for PurseCraft is very simple:
    1. We are only using lowercase letters as the value for the positions.
       The original implementation also uses numerical values, but sticking
       to lowercase letters should be enough for us to avoid collision problems.
    2. This cannot generate positions before "a". This is
       handled by returning `{:error, :cannot_go_before_a}`.

  """

  @doc """
  Generate a position between two positions.
  Returns {:ok, position} or {:error, reason}.

  ## Examples

      iex> between(nil, nil)
      {:ok, "m"}

      iex> between(nil, "m")
      {:ok, "g"}

      iex> between("m", nil)
      {:ok, "s"}

      iex> between("a", "c")
      {:ok, "b"}

      iex> between("a", "b")
      {:ok, "am"}
      
      iex> between(nil, "a")
      {:error, :cannot_go_before_a}
      
      iex> between("z", "a")
      {:error, :prev_must_be_less_than_next}
      
      iex> between("ABC", "def")
      {:error, :invalid_position}
  """
  @spec between(String.t() | nil, String.t() | nil) :: {:ok, String.t()} | {:error, atom()}
  def between(nil, nil), do: {:ok, "m"}

  def between(nil, next_pos) when is_binary(next_pos) do
    with :ok <- validate_position(next_pos) do
      if next_pos == "a" do
        {:error, :cannot_go_before_a}
      else
        {:ok, find_before(next_pos)}
      end
    end
  end

  def between(prev_pos, nil) when is_binary(prev_pos) do
    with :ok <- validate_position(prev_pos) do
      {:ok, find_after(prev_pos)}
    end
  end

  def between(prev_pos, next_pos) when is_binary(prev_pos) and is_binary(next_pos) do
    with :ok <- validate_position(prev_pos),
         :ok <- validate_position(next_pos),
         :ok <- validate_ordering(prev_pos, next_pos) do
      {:ok, find_between(prev_pos, next_pos)}
    end
  end

  def between(_prev, _next), do: {:error, :invalid_position}

  @doc """
  Generate initial positions for N items.
  Returns {:ok, positions} or {:error, reason}.

  ## Examples

      iex> initial_positions(3)
      {:ok, ["g", "m", "t"]}

      iex> initial_positions(5)
      {:ok, ["d", "i", "m", "q", "v"]}
      
      iex> initial_positions(0)
      {:ok, []}
      
      iex> initial_positions(-1)
      {:error, :invalid_count}
  """
  @spec initial_positions(integer()) :: {:ok, [String.t()]} | {:error, atom()}
  def initial_positions(count) when count < 0, do: {:error, :invalid_count}
  def initial_positions(0), do: {:ok, []}

  def initial_positions(count) when count > 0 do
    positions = generate_initial_positions(count)
    {:ok, positions}
  end

  # Generate evenly distributed positions based on count
  defp generate_initial_positions(1), do: ["m"]
  defp generate_initial_positions(2), do: ["h", "q"]
  defp generate_initial_positions(3), do: ["g", "m", "t"]
  defp generate_initial_positions(4), do: ["f", "k", "p", "u"]
  defp generate_initial_positions(5), do: ["d", "i", "m", "q", "v"]

  defp generate_initial_positions(count) when count <= 24 do
    # For small counts, distribute evenly between 'b' and 'y'
    step = 23.0 / (count + 1)

    Enum.map(1..count, fn i ->
      char_position = round(i * step) + ?b
      <<min(char_position, ?y)>>
    end)
  end

  defp generate_initial_positions(count) do
    # For large counts, use a more efficient approach with Stream
    # Generate positions lazily to avoid memory overhead
    single_chars = generate_single_chars()
    double_chars = generate_double_chars()
    triple_chars = generate_triple_chars(count)

    [single_chars, double_chars, triple_chars]
    |> Stream.concat()
    |> Enum.take(count)
    |> Enum.sort()
  end

  defp generate_single_chars, do: Stream.map(?b..?y, &<<&1>>)

  defp generate_double_chars do
    Stream.flat_map(?a..?z, fn first ->
      Stream.map(?a..?z, fn second -> <<first, second>> end)
    end)
  end

  defp generate_triple_chars(count) when count > 700 do
    Stream.flat_map(?a..?z, fn first ->
      Stream.flat_map(?a..?z, &generate_triple_char_combinations(first, &1))
    end)
  end

  defp generate_triple_chars(_count), do: Stream.concat([], [])

  defp generate_triple_char_combinations(first, second) do
    Stream.map(?a..?z, fn third -> <<first, second, third>> end)
  end

  @doc """
  Validate that a position string is valid.

  ## Examples

      iex> valid_position?("abc")
      true

      iex> valid_position?("ABC")
      false

      iex> valid_position?("")
      false
  """
  @spec valid_position?(any()) :: boolean()
  def valid_position?(position) when is_binary(position) do
    position != "" && all_lowercase_letters?(position)
  end

  def valid_position?(_position), do: false

  # More efficient than regex - checks if all characters are lowercase letters
  defp all_lowercase_letters?(<<>>), do: true

  defp all_lowercase_letters?(<<char, rest::binary>>) when char in ?a..?z do
    all_lowercase_letters?(rest)
  end

  defp all_lowercase_letters?(_binary), do: false

  # Private helper functions
  defp validate_position(position) do
    if valid_position?(position), do: :ok, else: {:error, :invalid_position}
  end

  defp validate_ordering(prev_pos, next_pos) when prev_pos >= next_pos do
    {:error, :prev_must_be_less_than_next}
  end

  defp validate_ordering(prev_pos, next_pos) do
    if adjacent?(prev_pos, next_pos) do
      {:error, :adjacent_positions}
    else
      :ok
    end
  end

  # Check if two positions are adjacent (no position can exist between them)
  defp adjacent?("a", "aa"), do: true
  defp adjacent?(_pos1, _pos2), do: false

  # Find a position that comes before the given string
  defp find_before("a" <> rest) when byte_size(rest) > 0, do: "a"

  defp find_before(<<char>>) when char > ?a do
    <<div(?a + char, 2)>>
  end

  defp find_before(<<first_char, _rest::binary>>) when first_char > ?a do
    <<div(?a + first_char, 2)>>
  end

  # coveralls-ignore-start
  defp find_before(_str), do: "a"
  # coveralls-ignore-stop

  # Find a position that comes after the given string
  defp find_after(str) do
    # Use binary pattern matching to get last character more efficiently
    str_size = byte_size(str)
    <<prefix::binary-size(str_size - 1), last_char>> = str

    if last_char < ?z do
      # Can increment the last character
      <<prefix::binary, last_char + 1>>
    else
      # Last char is 'z', append a character
      <<str::binary, ?m>>
    end
  end

  # Find a position between two strings
  defp find_between(start_str, end_str) do
    start_chars = to_charlist(start_str)
    end_chars = to_charlist(end_str)

    start_chars
    |> find_midpoint_chars(end_chars, [])
    |> List.to_string()
  end

  # Recursively find the midpoint between two character lists
  # Pattern: matching head characters
  defp find_midpoint_chars([h | t1], [h | t2], acc) do
    find_midpoint_chars(t1, t2, [h | acc])
  end

  # Pattern: gap between characters - can insert midpoint
  defp find_midpoint_chars([c1 | _rest1], [c2 | _rest2], acc) when c2 - c1 > 1 do
    build_result(acc, [div(c1 + c2, 2)])
  end

  # Pattern: adjacent characters - need to extend
  defp find_midpoint_chars([c1 | []], [c2 | _rest], acc) when c2 - c1 == 1 do
    # Last character of first string, append 'm'
    build_result(acc, [c1, ?m])
  end

  defp find_midpoint_chars([c1 | [next | _tail] = _t1], [c2 | _rest], acc) when c2 - c1 == 1 do
    # More characters exist, find midpoint after current character
    suffix = if next < ?z, do: [c1, div(next + ?z, 2)], else: [c1, next, ?m]
    build_result(acc, suffix)
  end

  # Pattern: first string is shorter
  defp find_midpoint_chars([], [c | _rest], acc) when c > ?a do
    build_result(acc, [div(?a + c, 2)])
  end

  # coveralls-ignore-start
  defp find_midpoint_chars([], [?a | _rest], acc) do
    build_result(acc, [?a])
  end

  # coveralls-ignore-stop

  # Pattern: second string is shorter, last character
  # coveralls-ignore-start
  defp find_midpoint_chars([c], [], acc) do
    suffix = if c < ?z, do: [div(c + ?z, 2)], else: [c, ?m]
    build_result(acc, suffix)
  end

  # coveralls-ignore-stop

  # Pattern: second string is shorter, more characters exist
  # coveralls-ignore-start
  defp find_midpoint_chars([c | [next | _tail] = _t], [], acc) do
    suffix = if next < ?z, do: [c, div(next + ?z, 2)], else: [c, next, ?m]
    build_result(acc, suffix)
  end

  # coveralls-ignore-stop

  # Pattern: equal strings (shouldn't happen in normal usage)
  # coveralls-ignore-start
  defp find_midpoint_chars([], [], acc) do
    build_result(acc, [?m])
  end

  # coveralls-ignore-stop

  defp build_result(acc, suffix) do
    Enum.reverse(acc, suffix)
  end
end
