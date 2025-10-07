defmodule PurseCraft.Utilities do
  @moduledoc """
  Provides utility functions that can be used across the application.
  """

  alias PurseCraft.Utilities.BuildSearchableFields
  alias PurseCraft.Utilities.MaybePreload
  alias PurseCraft.Utilities.PutHashedField
  alias PurseCraft.Utilities.Result

  @doc """
  Converts string keys in a map to atom keys.

  This function is useful when dealing with data from external sources
  (like forms or API requests) where keys are strings, but our schemas
  expect atom keys.

  Only converts existing atoms to prevent atom table pollution.
  Non-string keys are preserved as-is.

  ## Examples

      iex> Utilities.atomize_keys(%{"name" => "Test", "age" => 30})
      %{name: "Test", age: 30}

      iex> Utilities.atomize_keys(%{name: "Test", "age" => 30})
      %{name: "Test", age: 30}

      iex> Utilities.atomize_keys(nil)
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

  @doc """
  Safely converts a result to a tuple format.
  Useful for ensuring consistent API responses.

  ## Examples

      iex> Utilities.to_result({:ok, %{}})
      {:ok, %{}}

      iex> Utilities.to_result(nil)
      {:error, :not_found}

      iex> Utilities.to_result(%{name: "test"})
      {:ok, %{name: "test"}}

  """
  @spec to_result(any()) :: {:ok, any()} | {:error, any()}
  defdelegate to_result(value), to: Result, as: :normalize

  @doc """
  Preloads associations on a struct or list of structs if preloads are provided in options.

  ## Examples

      iex> Utilities.maybe_preload(%User{}, [])
      %User{}

      iex> Utilities.maybe_preload(%User{}, preload: [:workspaces])
      %User{workspaces: [...]}

      iex> Utilities.maybe_preload([%User{}], preload: [:workspaces])
      [%User{workspaces: [...]}]

      iex> Utilities.maybe_preload(nil, preload: [:workspaces])
      nil

  """
  @spec maybe_preload(struct() | [struct()] | nil, keyword()) :: struct() | [struct()] | nil
  defdelegate maybe_preload(data, opts), to: MaybePreload, as: :call

  @doc """
  Puts hash values for encrypted fields in a changeset.

  ## Examples

      iex> Utilities.put_hashed_field(changeset, [:name, :email])
      %Ecto.Changeset{}

      iex> Utilities.put_hashed_field(changeset, :name)
      %Ecto.Changeset{}

  """
  @spec put_hashed_field(Ecto.Changeset.t(), [atom()] | atom()) :: Ecto.Changeset.t()
  defdelegate put_hashed_field(changeset, fields), to: PutHashedField, as: :call

  @doc """
  Builds a searchable fields map from a struct.

  Takes a struct and a list of field names (atoms) to extract.
  Only includes fields that have non-nil, non-empty string values.

  ## Examples

      iex> transaction = %{memo: "Groceries", amount: 2500}
      iex> Utilities.build_searchable_fields(transaction, [:memo])
      %{"memo" => "Groceries"}

  """
  @spec build_searchable_fields(struct() | map(), [atom()]) :: %{String.t() => String.t()}
  defdelegate build_searchable_fields(struct, field_names), to: BuildSearchableFields, as: :call
end
