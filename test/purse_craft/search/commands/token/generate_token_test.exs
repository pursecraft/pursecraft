defmodule PurseCraft.Search.Commands.Token.GenerateTokenTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Search.Commands.Token.GenerateToken

  describe "call/2" do
    test "generates token data structures for valid text" do
      result = GenerateToken.call("hello", "name")

      expected = [
        %{
          field_name: "name",
          token_hash: "hel",
          algorithm_version: 1,
          token_length: 3
        },
        %{
          field_name: "name",
          token_hash: "ell",
          algorithm_version: 1,
          token_length: 3
        },
        %{
          field_name: "name",
          token_hash: "llo",
          algorithm_version: 1,
          token_length: 3
        }
      ]

      assert result == expected
    end

    test "includes field name in each token" do
      result = GenerateToken.call("test", "description")

      assert Enum.all?(result, &(&1.field_name == "description"))
    end

    test "includes current algorithm version in each token" do
      result = GenerateToken.call("test", "name")

      assert Enum.all?(result, &(&1.algorithm_version == 1))
    end

    test "includes token length in each token" do
      result = GenerateToken.call("test", "name")

      assert Enum.all?(result, &(&1.token_length == 3))
    end

    test "returns empty list for text shorter than 3 characters" do
      result = GenerateToken.call("hi", "name")

      assert result == []
    end

    test "returns empty list for empty string" do
      result = GenerateToken.call("", "name")

      assert result == []
    end

    test "handles multiple words" do
      result = GenerateToken.call("hello world", "name")

      token_hashes = Enum.map(result, & &1.token_hash)
      expected_hashes = ["hel", "ell", "llo", "wor", "orl", "rld"]

      assert token_hashes == expected_hashes
      assert Enum.all?(result, &(&1.field_name == "name"))
    end

    test "handles unicode text" do
      result = GenerateToken.call("café", "name")

      token_hashes = Enum.map(result, & &1.token_hash)
      expected_hashes = ["caf", "afé"]

      assert token_hashes == expected_hashes
    end

    test "filters out stop words through ngram generation" do
      result = GenerateToken.call("the hello world", "name")

      token_hashes = Enum.map(result, & &1.token_hash)

      refute "the" in token_hashes
      assert "hel" in token_hashes
      assert "wor" in token_hashes
    end
  end

  describe "get_current_algorithm_version/0" do
    test "returns current algorithm version" do
      assert GenerateToken.get_current_algorithm_version() == 1
    end
  end
end
