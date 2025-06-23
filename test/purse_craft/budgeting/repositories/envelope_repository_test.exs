defmodule PurseCraft.Budgeting.Repositories.EnvelopeRepositoryTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Budgeting.Repositories.EnvelopeRepository
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory

  describe "create/1" do
    test "with valid data creates an envelope" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      attrs = %{name: "Test Envelope", category_id: category.id, position: "m"}

      assert {:ok, envelope} = EnvelopeRepository.create(attrs)
      assert envelope.name == "Test Envelope"
      assert envelope.category_id == category.id
      assert envelope.position == "m"
    end

    test "with invalid data returns error changeset" do
      attrs = %{name: ""}

      assert {:error, changeset} = EnvelopeRepository.create(attrs)

      assert %{name: ["can't be blank"], category_id: ["can't be blank"], position: ["can't be blank"]} =
               errors_on(changeset)
    end

    test "with duplicate position within same category returns error" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      BudgetingFactory.insert(:envelope, category_id: category.id, position: "m")

      attrs = %{name: "Duplicate Position", category_id: category.id, position: "m"}

      assert {:error, changeset} = EnvelopeRepository.create(attrs)
      assert %{position: ["has already been taken"]} = errors_on(changeset)
    end

    test "allows same position in different categories" do
      book = CoreFactory.insert(:book)
      category1 = BudgetingFactory.insert(:category, book_id: book.id)
      category2 = BudgetingFactory.insert(:category, book_id: book.id)
      BudgetingFactory.insert(:envelope, category_id: category1.id, position: "m")

      attrs = %{name: "Same Position Different Category", category_id: category2.id, position: "m"}

      assert {:ok, envelope} = EnvelopeRepository.create(attrs)
      assert envelope.position == "m"
      assert envelope.category_id == category2.id
    end
  end

  describe "get_by_external_id_and_book_id/3" do
    test "returns envelope when found" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      result = EnvelopeRepository.get_by_external_id_and_book_id(envelope.external_id, book.id)

      assert result.id == envelope.id
      assert result.name == envelope.name
    end

    test "returns nil when envelope not found" do
      book = CoreFactory.insert(:book)

      result = EnvelopeRepository.get_by_external_id_and_book_id(Ecto.UUID.generate(), book.id)

      assert result == nil
    end

    test "returns nil when envelope exists but in different book" do
      book1 = CoreFactory.insert(:book)
      book2 = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book1.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      result = EnvelopeRepository.get_by_external_id_and_book_id(envelope.external_id, book2.id)

      assert result == nil
    end

    test "with preload option returns envelope with preloaded associations" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      result = EnvelopeRepository.get_by_external_id_and_book_id(envelope.external_id, book.id, preload: [:category])

      assert result.id == envelope.id
      assert result.category.id == category.id
      assert result.category.name == category.name
    end
  end

  describe "update/2" do
    test "with valid data updates an envelope" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id, name: "Original Name")
      attrs = %{name: "Updated Name"}

      assert {:ok, updated_envelope} = EnvelopeRepository.update(envelope, attrs)
      assert updated_envelope.id == envelope.id
      assert updated_envelope.name == "Updated Name"
      assert updated_envelope.category_id == category.id
    end

    test "with invalid data returns error changeset" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)
      attrs = %{name: ""}

      assert {:error, changeset} = EnvelopeRepository.update(envelope, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "delete/1" do
    test "deletes an envelope" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

      assert {:ok, deleted_envelope} = EnvelopeRepository.delete(envelope)
      assert deleted_envelope.id == envelope.id
    end
  end

  describe "get_first_position/1" do
    test "returns the position of the first envelope in a category" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      BudgetingFactory.insert(:envelope, category_id: category.id, position: "g")
      BudgetingFactory.insert(:envelope, category_id: category.id, position: "m")
      BudgetingFactory.insert(:envelope, category_id: category.id, position: "s")

      result = EnvelopeRepository.get_first_position(category.id)

      assert result == "g"
    end

    test "returns nil when category has no envelopes" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)

      result = EnvelopeRepository.get_first_position(category.id)

      assert result == nil
    end

    test "returns correct position when only one envelope exists" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      BudgetingFactory.insert(:envelope, category_id: category.id, position: "m")

      result = EnvelopeRepository.get_first_position(category.id)

      assert result == "m"
    end

    test "returns correct position with complex ordering" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      BudgetingFactory.insert(:envelope, category_id: category.id, position: "mm")
      BudgetingFactory.insert(:envelope, category_id: category.id, position: "ma")
      BudgetingFactory.insert(:envelope, category_id: category.id, position: "m")
      BudgetingFactory.insert(:envelope, category_id: category.id, position: "s")

      result = EnvelopeRepository.get_first_position(category.id)

      assert result == "m"
    end
  end

  describe "list_by_external_ids/2" do
    test "returns envelopes matching the given external IDs" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      env1 = BudgetingFactory.insert(:envelope, category_id: category.id, position: "g")
      env2 = BudgetingFactory.insert(:envelope, category_id: category.id, position: "m")
      env3 = BudgetingFactory.insert(:envelope, category_id: category.id, position: "t")

      BudgetingFactory.insert(:envelope, category_id: category.id, position: "z")

      external_ids = [env1.external_id, env2.external_id, env3.external_id]
      result = EnvelopeRepository.list_by_external_ids(external_ids)

      assert length(result) == 3
      result_external_ids = Enum.map(result, & &1.external_id)
      assert Enum.all?(external_ids, &(&1 in result_external_ids))
    end

    test "returns empty list when no envelopes match the external IDs" do
      result = EnvelopeRepository.list_by_external_ids([Ecto.UUID.generate(), Ecto.UUID.generate()])

      assert result == []
    end

    test "returns subset when only some external IDs match" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      env1 = BudgetingFactory.insert(:envelope, category_id: category.id, position: "g")

      external_ids = [env1.external_id, Ecto.UUID.generate(), Ecto.UUID.generate()]
      result = EnvelopeRepository.list_by_external_ids(external_ids)

      assert length(result) == 1
      assert hd(result).external_id == env1.external_id
    end

    test "with preload option returns envelopes with preloaded associations" do
      book = CoreFactory.insert(:book)
      category1 = BudgetingFactory.insert(:category, book_id: book.id)
      category2 = BudgetingFactory.insert(:category, book_id: book.id)
      env1 = BudgetingFactory.insert(:envelope, category_id: category1.id, position: "g")
      env2 = BudgetingFactory.insert(:envelope, category_id: category2.id, position: "m")

      external_ids = [env1.external_id, env2.external_id]
      result = EnvelopeRepository.list_by_external_ids(external_ids, preload: [:category])

      assert length(result) == 2

      env1_result = Enum.find(result, &(&1.external_id == env1.external_id))
      env2_result = Enum.find(result, &(&1.external_id == env2.external_id))

      assert env1_result.category.id == category1.id
      assert env2_result.category.id == category2.id
    end

    test "handles empty list of external IDs" do
      result = EnvelopeRepository.list_by_external_ids([])

      assert result == []
    end
  end

  describe "update_position/2" do
    test "updates the position of an envelope with valid position" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id, position: "g")

      assert {:ok, updated_envelope} = EnvelopeRepository.update_position(envelope, "m", category.id)
      assert updated_envelope.position == "m"
      assert updated_envelope.id == envelope.id
      assert updated_envelope.name == envelope.name
    end

    test "returns error changeset with invalid position format" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id, position: "g")

      assert {:error, changeset} = EnvelopeRepository.update_position(envelope, "ABC", category.id)
      assert %{position: ["must contain only lowercase letters"]} = errors_on(changeset)
    end

    test "returns error changeset with empty position" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id, position: "g")

      assert {:error, changeset} = EnvelopeRepository.update_position(envelope, "", category.id)
      assert %{position: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset when position violates unique constraint" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      BudgetingFactory.insert(:envelope, category_id: category.id, position: "g")
      env2 = BudgetingFactory.insert(:envelope, category_id: category.id, position: "m")

      assert {:error, changeset} = EnvelopeRepository.update_position(env2, "g", category.id)
      assert %{position: ["has already been taken"]} = errors_on(changeset)
    end

    test "allows same position in different categories" do
      book = CoreFactory.insert(:book)
      category1 = BudgetingFactory.insert(:category, book_id: book.id)
      category2 = BudgetingFactory.insert(:category, book_id: book.id)
      BudgetingFactory.insert(:envelope, category_id: category1.id, position: "g")
      env2 = BudgetingFactory.insert(:envelope, category_id: category2.id, position: "m")

      assert {:ok, updated_envelope} = EnvelopeRepository.update_position(env2, "g", category2.id)
      assert updated_envelope.position == "g"
    end

    test "allows updating position to same position" do
      book = CoreFactory.insert(:book)
      category = BudgetingFactory.insert(:category, book_id: book.id)
      envelope = BudgetingFactory.insert(:envelope, category_id: category.id, position: "g")

      assert {:ok, updated_envelope} = EnvelopeRepository.update_position(envelope, "g", category.id)
      assert updated_envelope.position == "g"
      assert updated_envelope.id == envelope.id
    end
  end
end
