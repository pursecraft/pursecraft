defmodule PurseCraft.Utilities.MaybePreload do
  @moduledoc """
  Utilities for conditionally preloading associations on Ecto structs.
  """

  alias PurseCraft.Repo

  @doc """
  Preloads associations on a struct or list of structs if preloads are provided in options.

  This is a common pattern where we want to conditionally preload associations
  based on options passed to repository functions. Extracts the `:preload` key
  from the options and preloads those associations.

  ## Examples

      iex> call(%User{}, [])
      %User{}

      iex> call(%User{}, preload: [:books])
      %User{books: [...]}

      iex> call([%User{}, %User{}], preload: [:books])
      [%User{books: [...]}, %User{books: [...]}]

      iex> call(nil, preload: [:books])
      nil

      iex> call([], preload: [:books])
      []

  """

  @spec call(struct() | [struct()] | nil, keyword()) :: struct() | [struct()] | nil
  def call(nil, _opts), do: nil

  def call(data, opts) when is_list(opts) do
    preloads = Keyword.get(opts, :preload, [])
    if preloads == [], do: data, else: Repo.preload(data, preloads)
  end
end
