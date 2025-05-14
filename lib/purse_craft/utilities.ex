defmodule PurseCraft.Utilities do
  @moduledoc """
  Provides utility functions that can be used across the application.
  """

  @doc """
  Converts string keys in a map to atom keys.

  This function is useful when dealing with data from external sources
  (like forms or API requests) where keys are strings, but our schemas
  expect atom keys.

  Only converts existing atoms to prevent atom table pollution.
  Non-string keys are preserved as-is.

  ## Examples

      iex> PurseCraft.Utilities.atomize_keys(%{"name" => "Test", "age" => 30})
      %{name: "Test", age: 30}

      iex> PurseCraft.Utilities.atomize_keys(%{name: "Test", "age" => 30})
      %{name: "Test", age: 30}

      iex> PurseCraft.Utilities.atomize_keys(nil)
      nil

  """
  @spec atomize_keys(map() | nil) :: map() | nil
  def atomize_keys(nil), do: nil
  def atomize_keys(map) when not is_map(map), do: map

  def atomize_keys(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_binary(key) -> {String.to_existing_atom(key), value}
      {key, value} -> {key, value}
    end)
  end
end
