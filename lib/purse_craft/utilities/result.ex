defmodule PurseCraft.Utilities.Result do
  @moduledoc """
  Utilities for normalizing function results into consistent tuple patterns.
  """

  @doc """
  Normalizes various result patterns into consistent {:ok, data} | {:error, reason} tuples.

  ## Examples

      iex> PurseCraft.Utilities.Result.normalize({:ok, %{}})
      {:ok, %{}}

      iex> PurseCraft.Utilities.Result.normalize({:error, :not_found})
      {:error, :not_found}

      iex> PurseCraft.Utilities.Result.normalize(nil)
      {:error, :not_found}

      iex> PurseCraft.Utilities.Result.normalize(%{name: "test"})
      {:ok, %{name: "test"}}

  """
  @spec normalize(any()) :: {:ok, any()} | {:error, any()}
  def normalize({:ok, data}), do: {:ok, data}
  def normalize({:error, reason}), do: {:error, reason}
  def normalize(nil), do: {:error, :not_found}
  def normalize(data), do: {:ok, data}
end
