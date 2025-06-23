defmodule PurseCraft.Utilities.MaybePreload do
  @moduledoc """
  Utilities for conditionally preloading associations on Ecto structs.
  """

  @doc """
  Preloads associations on a struct if preloads are provided.

  ## Examples

      iex> call(%User{}, [])
      %User{}

      iex> call(%User{}, [:books])
      %User{books: [...]}

      iex> call(nil, [:books])
      nil

  """
  @spec call(struct() | nil, list()) :: struct() | nil
  def call(nil, _preloads), do: nil
  def call(struct, []), do: struct

  def call(struct, preloads) when is_list(preloads) do
    PurseCraft.Repo.preload(struct, preloads)
  end
end
