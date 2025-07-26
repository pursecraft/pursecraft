defmodule PurseCraft.Search.Commands.Token.GenerateToken do
  @moduledoc """
  Generates search token data structures for database insertion.

  Takes text and field information and produces token maps ready for 
  SearchToken schema insertion.
  """

  alias PurseCraft.Search.Commands.Ngram.GenerateNgram

  @current_algorithm_version 1

  @type token_attrs :: %{
          field_name: String.t(),
          token_hash: String.t(),
          algorithm_version: integer(),
          token_length: integer()
        }

  @spec call(String.t(), String.t()) :: list(token_attrs())
  def call(text, field_name) when is_binary(text) and byte_size(text) >= 3 do
    ngrams = GenerateNgram.call(text)

    Enum.map(ngrams, fn ngram ->
      %{
        field_name: field_name,
        token_hash: ngram,
        algorithm_version: @current_algorithm_version,
        token_length: String.length(ngram)
      }
    end)
  end

  def call(_text, _field_name), do: []

  @spec get_current_algorithm_version() :: integer()
  def get_current_algorithm_version, do: @current_algorithm_version
end
