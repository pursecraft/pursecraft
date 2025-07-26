defmodule PurseCraft.Search.Commands.Ngram.GenerateNgram do
  @moduledoc """
  Generates n-gram tokens from text for searchable encryption.

  Current implementation (Algorithm v1): Simple 3-character n-grams for Latin scripts.
  Designed for graceful degradation with international text and future algorithm upgrades.
  """

  @stop_words ~w(the and or of in to for a an)
  @max_tokens_per_field 100

  @type opts :: [token_length: non_neg_integer()]

  @spec call(String.t(), opts()) :: list(String.t())
  def call(text, opts \\ []) do
    token_length = Keyword.get(opts, :token_length, 3)

    text
    |> String.downcase()
    |> String.normalize(:nfc)
    |> String.replace(~r/[^\p{L}\p{N}\-\s]/u, " ")
    |> String.split()
    |> Enum.reject(&(&1 in @stop_words))
    |> Enum.flat_map(&extract_ngrams(&1, token_length))
    |> Enum.uniq()
    |> Enum.take(@max_tokens_per_field)
  end

  defp extract_ngrams(word, token_length) when byte_size(word) >= token_length do
    word
    |> String.graphemes()
    |> Enum.chunk_every(token_length, 1, :discard)
    |> Enum.map(&Enum.join/1)
  end

  defp extract_ngrams(_word, _token_length), do: []
end
