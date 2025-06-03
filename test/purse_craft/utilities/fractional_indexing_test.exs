defmodule PurseCraft.Utilities.FractionalIndexingTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Utilities.FractionalIndexing

  describe "between/2" do
    test "generates middle position when both nil" do
      assert {:ok, "m"} = FractionalIndexing.between(nil, nil)
    end

    test "generates position before next when prev is nil" do
      assert {:ok, position} = FractionalIndexing.between(nil, "m")
      assert position < "m"
      assert FractionalIndexing.valid_position?(position)
    end

    test "handles the 'cannot go before a' boundary limitation" do
      assert {:error, :cannot_go_before_a} = FractionalIndexing.between(nil, "a")

      assert {:ok, pos_before_b} = FractionalIndexing.between(nil, "b")
      assert pos_before_b < "b"
      assert pos_before_b >= "a"

      assert {:ok, pos_before_aa} = FractionalIndexing.between(nil, "aa")
      assert pos_before_aa < "aa"
      assert pos_before_aa == "a"
    end

    test "generates position after prev when next is nil" do
      assert {:ok, position} = FractionalIndexing.between("m", nil)
      assert position > "m"
      assert FractionalIndexing.valid_position?(position)

      assert {:ok, position_after_z} = FractionalIndexing.between("z", nil)
      assert position_after_z > "z"
      assert FractionalIndexing.valid_position?(position_after_z)
    end

    test "generates position between two positions" do
      assert {:ok, position} = FractionalIndexing.between("a", "c")
      assert position > "a"
      assert position < "c"
      assert FractionalIndexing.valid_position?(position)
    end

    test "handles adjacent positions" do
      assert {:ok, position} = FractionalIndexing.between("a", "b")
      assert position > "a"
      assert position < "b"
      assert FractionalIndexing.valid_position?(position)

      assert {:ok, pos2} = FractionalIndexing.between("a", position)
      assert {:ok, pos3} = FractionalIndexing.between(position, "b")
      assert "a" < pos2 and pos2 < position and position < pos3 and pos3 < "b"
    end

    test "handles multiple character positions" do
      assert {:ok, position} = FractionalIndexing.between("aa", "ab")
      assert position > "aa"
      assert position < "ab"
      assert FractionalIndexing.valid_position?(position)
    end

    test "handles positions with different lengths" do
      assert {:error, :adjacent_positions} = FractionalIndexing.between("a", "aa")

      assert {:ok, position} = FractionalIndexing.between("a", "ab")
      assert position > "a"
      assert position < "ab"
    end

    test "returns error when prev >= next" do
      assert {:error, :prev_must_be_less_than_next} = FractionalIndexing.between("z", "a")
      assert {:error, :prev_must_be_less_than_next} = FractionalIndexing.between("m", "m")
      assert {:error, :prev_must_be_less_than_next} = FractionalIndexing.between("abc", "abc")
      assert {:error, :prev_must_be_less_than_next} = FractionalIndexing.between("b", "a")
    end

    test "returns error for invalid position strings" do
      assert {:error, :invalid_position} = FractionalIndexing.between("ABC", "def")
      assert {:error, :invalid_position} = FractionalIndexing.between("abc", "DEF")
      assert {:error, :invalid_position} = FractionalIndexing.between("ab1", "ab2")
      assert {:error, :invalid_position} = FractionalIndexing.between("", "abc")
      assert {:error, :invalid_position} = FractionalIndexing.between("abc", "")
      assert {:error, :invalid_position} = FractionalIndexing.between("a-b", "a-c")
      assert {:error, :invalid_position} = FractionalIndexing.between("a b", "a c")
      assert {:error, :invalid_position} = FractionalIndexing.between("café", "cage")
      assert {:error, :invalid_position} = FractionalIndexing.between("a😀", "b😀")
    end

    test "supports category repositioning workflow" do
      assert {:ok, categories} = FractionalIndexing.initial_positions(5)
      [cat1, cat2, _cat3, _cat4, cat5] = categories

      assert {:ok, cat4_new_pos} = FractionalIndexing.between(cat1, cat2)
      assert cat1 < cat4_new_pos and cat4_new_pos < cat2

      case FractionalIndexing.between(nil, cat1) do
        {:ok, cat5_new_pos} ->
          assert cat5_new_pos < cat1

        {:error, :cannot_go_before_a} ->
          assert true
      end

      assert {:ok, cat3_new_pos} = FractionalIndexing.between(cat5, nil)
      assert cat3_new_pos > cat5

      new_positions = [cat1, cat4_new_pos, cat2, cat3_new_pos]
      assert Enum.all?(new_positions, &FractionalIndexing.valid_position?/1)
    end

    test "can insert multiple items between positions" do
      pos1 = "a"
      pos2 = "z"

      assert {:ok, pos_middle} = FractionalIndexing.between(pos1, pos2)
      assert pos_middle > pos1
      assert pos_middle < pos2

      assert {:ok, pos_quarter} = FractionalIndexing.between(pos1, pos_middle)
      assert pos_quarter > pos1
      assert pos_quarter < pos_middle

      assert {:ok, pos_three_quarter} = FractionalIndexing.between(pos_middle, pos2)
      assert pos_three_quarter > pos_middle
      assert pos_three_quarter < pos2

      all_positions = [pos1, pos_quarter, pos_middle, pos_three_quarter, pos2]
      assert all_positions == Enum.sort(all_positions)
    end

    test "handles many insertions at the beginning" do
      positions = ["m"]

      new_positions =
        Enum.reduce(1..10, positions, fn _i, [first | _rest] = acc ->
          case FractionalIndexing.between(nil, first) do
            {:ok, new_pos} ->
              assert new_pos < first
              [new_pos | acc]

            {:error, :cannot_go_before_a} ->
              acc
          end
        end)

      assert length(new_positions) > 1
      assert new_positions == Enum.sort(new_positions)
      assert length(new_positions) == length(Enum.uniq(new_positions))
    end

    test "handles many insertions at the end" do
      positions = ["m"]

      new_positions =
        Enum.reduce(1..10, positions, fn _i, acc ->
          last = List.last(acc)
          {:ok, new_pos} = FractionalIndexing.between(last, nil)
          acc ++ [new_pos]
        end)

      assert length(new_positions) == 11
      assert new_positions == Enum.sort(new_positions)
      assert length(new_positions) == length(Enum.uniq(new_positions))
    end

    test "handles repeated insertions at same position (collision simulation)" do
      generated =
        Enum.map(1..10, fn _i ->
          {:ok, pos} = FractionalIndexing.between("m", "n")
          pos
        end)

      assert length(Enum.uniq(generated)) == 1

      positions =
        Enum.reduce(1..5, ["n", "m"], fn _i, [first | _rest] = acc ->
          {:ok, new_pos} = FractionalIndexing.between("m", first)
          [new_pos | acc]
        end)

      assert length(positions) == 7
      assert positions == Enum.uniq(positions)
    end

    test "density property - can always insert between any two valid positions" do
      test_pairs = [
        {"a", "z"},
        {"a", "b"},
        {"aa", "ab"},
        {"aaa", "aab"},
        {"m", "n"},
        {"zzz", "zzzz"}
      ]

      for {prev, next} <- test_pairs do
        assert {:ok, pos} = FractionalIndexing.between(prev, next)
        assert prev < pos and pos < next

        # Can insert between prev and new position
        assert {:ok, pos2} = FractionalIndexing.between(prev, pos)
        assert prev < pos2 and pos2 < pos

        # Can insert between new position and next
        assert {:ok, pos3} = FractionalIndexing.between(pos, next)
        assert pos < pos3 and pos3 < next
      end
    end

    test "unbounded property - can always extend the sequence" do
      after_positions = ["a", "m", "z", "zzz"]

      for pos <- after_positions do
        assert {:ok, new_pos} = FractionalIndexing.between(pos, nil)
        assert new_pos > pos
      end

      before_positions = ["b", "m", "z", "zzz"]

      for pos <- before_positions do
        assert {:ok, new_pos} = FractionalIndexing.between(nil, pos)
        assert new_pos < pos
      end
    end

    test "stability property - relative order never changes" do
      positions = ["d", "h", "m", "r", "w"]

      final_positions =
        Enum.reduce(1..20, positions, fn _i, acc ->
          sorted = Enum.sort(acc)
          idx = :rand.uniform(length(sorted) - 1) - 1
          prev = Enum.at(sorted, idx)
          next = Enum.at(sorted, idx + 1)

          {:ok, new_pos} = FractionalIndexing.between(prev, next)
          [new_pos | acc]
        end)

      sorted_final = Enum.sort(final_positions)

      original_indices =
        Enum.map(positions, fn pos ->
          Enum.find_index(sorted_final, &(&1 == pos))
        end)

      assert original_indices == Enum.sort(original_indices)
    end

    test "between with very long strings" do
      long_a = String.duplicate("a", 100)
      long_b = String.duplicate("a", 99) <> "b"

      assert {:ok, position} = FractionalIndexing.between(long_a, long_b)
      assert position > long_a
      assert position < long_b
      assert FractionalIndexing.valid_position?(position)
    end

    test "handles position after 'z'" do
      assert {:ok, position} = FractionalIndexing.between("z", nil)
      assert position > "z"
      assert FractionalIndexing.valid_position?(position)
    end

    test "handles complex edge cases" do
      assert {:ok, pos1} = FractionalIndexing.between("aaa", "aab")
      assert pos1 > "aaa"
      assert pos1 < "aab"

      assert {:ok, pos2} = FractionalIndexing.between("y", "z")
      assert pos2 > "y"
      assert pos2 < "z"
    end

    test "handles deeply nested positions" do
      deep_a = String.duplicate("a", 20)
      deep_b = String.duplicate("a", 19) <> "b"

      assert {:ok, position} = FractionalIndexing.between(deep_a, deep_b)
      assert position > deep_a
      assert position < deep_b
      assert FractionalIndexing.valid_position?(position)

      very_deep_a = String.duplicate("a", 50)
      very_deep_b = String.duplicate("a", 49) <> "b"

      assert {:ok, position2} = FractionalIndexing.between(very_deep_a, very_deep_b)
      assert position2 > very_deep_a
      assert position2 < very_deep_b
      assert FractionalIndexing.valid_position?(position2)
    end

    test "between operation is deterministic" do
      position_pairs = [
        {nil, nil},
        {nil, "m"},
        {"m", nil},
        {"a", "z"},
        {"abc", "def"}
      ]

      for {prev, next} <- position_pairs do
        results = Enum.map(1..10, fn _i -> FractionalIndexing.between(prev, next) end)

        assert length(Enum.uniq(results)) == 1
      end
    end
  end

  describe "initial_positions/1" do
    test "generates evenly distributed positions" do
      assert {:ok, positions} = FractionalIndexing.initial_positions(5)
      assert length(positions) == 5
      assert Enum.all?(positions, &FractionalIndexing.valid_position?/1)
      assert positions == Enum.sort(positions)
      assert length(positions) == length(Enum.uniq(positions))
    end

    test "generates evenly spaced positions" do
      assert {:ok, positions} = FractionalIndexing.initial_positions(3)
      assert length(positions) == 3

      assert hd(positions) > "a"
      assert List.last(positions) < "z"

      [first, second, third] = positions
      assert first < second
      assert second < third
    end

    test "generates well-distributed positions for various counts" do
      for count <- [1, 2, 5, 10, 20] do
        assert {:ok, positions} = FractionalIndexing.initial_positions(count)
        assert length(positions) == count
        assert positions == Enum.sort(positions)
        assert positions == Enum.uniq(positions)

        if count > 0 do
          assert hd(positions) > "a"
          assert List.last(positions) < "z"
        end
      end
    end

    test "handles single item" do
      assert {:ok, ["m"]} = FractionalIndexing.initial_positions(1)
    end

    test "handles empty list" do
      assert {:ok, []} = FractionalIndexing.initial_positions(0)
    end

    test "returns error for negative count" do
      assert {:error, :invalid_count} = FractionalIndexing.initial_positions(-1)
      assert {:error, :invalid_count} = FractionalIndexing.initial_positions(-10)
      assert {:error, :invalid_count} = FractionalIndexing.initial_positions(-100)
    end

    test "handles large number of items" do
      assert {:ok, positions} = FractionalIndexing.initial_positions(26)
      assert length(positions) == 26
      assert Enum.all?(positions, &FractionalIndexing.valid_position?/1)
      assert positions == Enum.sort(positions)
    end

    test "handles large counts by using multi-character positions" do
      assert {:ok, positions} = FractionalIndexing.initial_positions(50)
      assert length(positions) == 50
      assert positions == Enum.sort(positions)
      assert positions == Enum.uniq(positions)

      assert {:ok, positions} = FractionalIndexing.initial_positions(1000)
      assert length(positions) == 1000
      assert positions == Enum.uniq(positions)
    end

    test "handles very large counts" do
      assert {:ok, positions} = FractionalIndexing.initial_positions(10_000)
      assert length(positions) == 10_000
    end

    test "initial_positions is deterministic" do
      for count <- [1, 5, 10, 25] do
        results = Enum.map(1..5, fn _i -> FractionalIndexing.initial_positions(count) end)
        assert length(Enum.uniq(results)) == 1
      end
    end

    test "initial_positions generates well-distributed positions for existing categories" do
      for count <- [1, 5, 10, 20, 30] do
        assert {:ok, positions} = FractionalIndexing.initial_positions(count)
        assert length(positions) == count
        assert positions == Enum.sort(positions)
        assert positions == Enum.uniq(positions)

        if count > 1 do
          assert hd(positions) >= "a"
          assert List.last(positions) <= "z"

          assert hd(positions) != "a"
          assert List.last(positions) != "z"
        end
      end
    end

    test "can insert between any generated initial positions" do
      assert {:ok, positions} = FractionalIndexing.initial_positions(5)

      positions
      |> Enum.zip(tl(positions))
      |> Enum.each(fn {prev, next} ->
        assert {:ok, between} = FractionalIndexing.between(prev, next)
        assert prev < between and between < next
      end)
    end
  end

  describe "valid_position?/1" do
    test "validates lowercase letters" do
      assert FractionalIndexing.valid_position?("abc")
      assert FractionalIndexing.valid_position?("z")
      assert FractionalIndexing.valid_position?("abcdefghijklmnopqrstuvwxyz")
    end

    test "rejects uppercase letters" do
      refute FractionalIndexing.valid_position?("ABC")
      refute FractionalIndexing.valid_position?("Abc")
      refute FractionalIndexing.valid_position?("abC")
    end

    test "rejects empty string" do
      refute FractionalIndexing.valid_position?("")
    end

    test "rejects non-string values" do
      refute FractionalIndexing.valid_position?(nil)
      refute FractionalIndexing.valid_position?(123)
      refute FractionalIndexing.valid_position?(:atom)
      refute FractionalIndexing.valid_position?([])
      refute FractionalIndexing.valid_position?(%{})
    end

    test "rejects strings with numbers" do
      refute FractionalIndexing.valid_position?("a1b")
      refute FractionalIndexing.valid_position?("123")
    end

    test "rejects strings with special characters" do
      refute FractionalIndexing.valid_position?("a-b")
      refute FractionalIndexing.valid_position?("a_b")
      refute FractionalIndexing.valid_position?("a b")
    end

    test "rejects non-ASCII characters" do
      refute FractionalIndexing.valid_position?("café")
      refute FractionalIndexing.valid_position?("αβγ")
      refute FractionalIndexing.valid_position?("a😀b")
      refute FractionalIndexing.valid_position?("aña")
    end
  end
end
