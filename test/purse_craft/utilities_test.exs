defmodule PurseCraft.UtilitiesTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Utilities

  describe "atomize_keys/1" do
    test "converts string keys to atom keys" do
      input = %{"name" => "Test Category", "priority" => 1}
      expected = %{name: "Test Category", priority: 1}

      assert Utilities.atomize_keys(input) == expected
    end

    test "preserves existing atom keys" do
      initial_map = %{name: "Test Category"}
      input_with_string_key = Map.put(initial_map, "priority", 1)
      expected = %{name: "Test Category", priority: 1}

      assert Utilities.atomize_keys(input_with_string_key) == expected
    end

    test "handles nil input" do
      assert Utilities.atomize_keys(nil) == nil
    end

    test "handles non-map input" do
      assert Utilities.atomize_keys("not a map") == "not a map"
    end

    test "only converts keys to existing atoms" do
      standard_input = %{"name" => "Test", "priority" => 1}
      assert %{name: "Test", priority: 1} = Utilities.atomize_keys(standard_input)

      assert_raise ArgumentError, fn ->
        Utilities.atomize_keys(%{"non_existent_atom_key" => "value"})
      end
    end
  end
end
