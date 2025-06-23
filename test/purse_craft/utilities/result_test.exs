defmodule PurseCraft.Utilities.ResultTest do
  use ExUnit.Case, async: true

  alias PurseCraft.Utilities.Result

  describe "normalize/1" do
    test "returns ok tuples unchanged" do
      assert Result.normalize({:ok, "data"}) == {:ok, "data"}
      assert Result.normalize({:ok, %{key: "value"}}) == {:ok, %{key: "value"}}
      assert Result.normalize({:ok, nil}) == {:ok, nil}
    end

    test "returns error tuples unchanged" do
      assert Result.normalize({:error, :not_found}) == {:error, :not_found}
      assert Result.normalize({:error, "message"}) == {:error, "message"}
      assert Result.normalize({:error, %{field: ["error"]}}) == {:error, %{field: ["error"]}}
    end

    test "converts nil to error tuple" do
      assert Result.normalize(nil) == {:error, :not_found}
    end

    test "wraps other values in ok tuple" do
      assert Result.normalize("data") == {:ok, "data"}
      assert Result.normalize(%{key: "value"}) == {:ok, %{key: "value"}}
      assert Result.normalize(123) == {:ok, 123}
      assert Result.normalize([1, 2, 3]) == {:ok, [1, 2, 3]}
    end
  end
end
