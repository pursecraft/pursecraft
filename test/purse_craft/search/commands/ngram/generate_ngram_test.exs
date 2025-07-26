defmodule PurseCraft.Search.Commands.Ngram.GenerateNgramTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Search.Commands.Ngram.GenerateNgram

  describe "call/2" do
    test "generates 3-character n-grams by default" do
      result = GenerateNgram.call("hello")

      assert result == ["hel", "ell", "llo"]
    end

    test "generates n-grams with custom token length" do
      result = GenerateNgram.call("hello", token_length: 2)

      assert result == ["he", "el", "ll", "lo"]
    end

    test "handles multiple words" do
      result = GenerateNgram.call("hello world")

      assert result == ["hel", "ell", "llo", "wor", "orl", "rld"]
    end

    test "removes stop words" do
      result = GenerateNgram.call("the hello and world")

      assert result == ["hel", "ell", "llo", "wor", "orl", "rld"]
    end

    test "normalizes to lowercase" do
      result = GenerateNgram.call("HELLO World")

      assert result == ["hel", "ell", "llo", "wor", "orl", "rld"]
    end

    test "normalizes unicode characters" do
      result = GenerateNgram.call("café")

      assert result == ["caf", "afé"]
    end

    test "removes special characters except hyphens" do
      result = GenerateNgram.call("hello-world! @#$%")

      assert result == ["hel", "ell", "llo", "lo-", "o-w", "-wo", "wor", "orl", "rld"]
    end

    test "preserves hyphens in text" do
      result = GenerateNgram.call("co-worker")

      assert result == ["co-", "o-w", "-wo", "wor", "ork", "rke", "ker"]
    end

    test "skips words shorter than token length" do
      result = GenerateNgram.call("hi hello", token_length: 3)

      assert result == ["hel", "ell", "llo"]
    end

    test "returns unique tokens only" do
      result = GenerateNgram.call("hello hello")

      assert result == ["hel", "ell", "llo"]
    end

    test "respects maximum tokens per field limit" do
      long_text = Enum.map_join(1..50, " ", &"word#{&1}extra")
      result = GenerateNgram.call(long_text)

      assert length(result) <= 100
    end

    test "handles empty string" do
      result = GenerateNgram.call("")

      assert result == []
    end

    test "handles string with only stop words" do
      result = GenerateNgram.call("the and or")

      assert result == []
    end

    test "handles string with only special characters" do
      result = GenerateNgram.call("!@#$%^&*()")

      assert result == []
    end

    test "handles numbers and letters together" do
      result = GenerateNgram.call("abc123")

      assert result == ["abc", "bc1", "c12", "123"]
    end

    test "preserves order of first occurrence for unique tokens" do
      result = GenerateNgram.call("hello world hello")

      expected = ["hel", "ell", "llo", "wor", "orl", "rld"]
      assert result == expected
    end
  end
end
