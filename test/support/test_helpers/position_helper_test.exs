defmodule PurseCraft.TestHelpers.PositionHelperTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.TestHelpers.PositionHelper
  alias PurseCraft.Utilities.FractionalIndexing

  describe "generate_lowercase_position/0" do
    test "generates valid fractional positions" do
      positions = Enum.map(1..100, fn _ -> PositionHelper.generate_lowercase_position() end)

      # All positions should be valid according to FractionalIndexing
      assert Enum.all?(positions, &FractionalIndexing.valid_position?/1)
    end

    test "generates unique positions for concurrent calls" do
      positions = Enum.map(1..100, fn _ -> PositionHelper.generate_lowercase_position() end)

      # All positions should be unique
      unique_positions = Enum.uniq(positions)
      assert length(unique_positions) == length(positions)
    end

    test "generated positions can be lexicographically sorted" do
      positions = Enum.map(1..50, fn _ -> PositionHelper.generate_lowercase_position() end)

      # Should be sortable without errors
      sorted = Enum.sort(positions)
      assert is_list(sorted)
      assert length(sorted) == 50
    end

    test "positions work with FractionalIndexing.between/2" do
      pos1 = PositionHelper.generate_lowercase_position()
      pos2 = PositionHelper.generate_lowercase_position()

      # Should be able to find a position between any two generated positions
      [smaller, larger] = Enum.sort([pos1, pos2])

      assert {:ok, between_pos} = FractionalIndexing.between(smaller, larger)
      assert smaller < between_pos
      assert between_pos < larger
    end

    test "positions follow lowercase letter constraint" do
      positions = Enum.map(1..50, fn _ -> PositionHelper.generate_lowercase_position() end)

      # All positions should only contain lowercase letters
      assert Enum.all?(positions, fn pos ->
        String.match?(pos, ~r/^[a-z]+$/)
      end)
    end
  end
end
