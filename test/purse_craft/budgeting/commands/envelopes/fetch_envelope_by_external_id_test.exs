defmodule PurseCraft.Budgeting.Commands.Envelopes.FetchEnvelopeByExternalIdTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Envelopes.FetchEnvelopeByExternalId
  alias PurseCraft.Budgeting.Repositories.EnvelopeRepository
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory

  setup do
    book = CoreFactory.insert(:book)
    category = BudgetingFactory.insert(:category, book_id: book.id)

    %{
      book: book,
      category: category
    }
  end

  describe "call/4" do
    test "with owner role (authorized scope) returns envelope", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      envelope = %Envelope{id: 1, name: "Test Envelope", category_id: category.id, external_id: Ecto.UUID.generate()}

      stub(EnvelopeRepository, :get_by_external_id_and_book_id, fn external_id, book_id, _opts ->
        assert external_id == envelope.external_id
        assert book_id == book.id
        envelope
      end)

      assert {:ok, ^envelope} = FetchEnvelopeByExternalId.call(scope, book, envelope.external_id)
    end

    test "with preload option returns envelope with preloaded associations", %{
      book: book,
      category: category
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      envelope = %Envelope{
        id: 1,
        name: "Test Envelope",
        category_id: category.id,
        external_id: Ecto.UUID.generate(),
        category: category
      }

      stub(EnvelopeRepository, :get_by_external_id_and_book_id, fn external_id, book_id, opts ->
        assert external_id == envelope.external_id
        assert book_id == book.id
        assert opts == [preload: [:category]]
        envelope
      end)

      assert {:ok, ^envelope} = FetchEnvelopeByExternalId.call(scope, book, envelope.external_id, preload: [:category])
    end

    test "with invalid external_id returns not found error", %{book: book} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      external_id = Ecto.UUID.generate()

      stub(EnvelopeRepository, :get_by_external_id_and_book_id, fn ^external_id, _book_id, _opts ->
        nil
      end)

      assert {:error, :not_found} = FetchEnvelopeByExternalId.call(scope, book, external_id)
    end

    test "with editor role (authorized scope) returns envelope", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      envelope = %Envelope{id: 1, name: "Editor Envelope", category_id: category.id, external_id: Ecto.UUID.generate()}

      stub(EnvelopeRepository, :get_by_external_id_and_book_id, fn _external_id, _book_id, _opts ->
        envelope
      end)

      assert {:ok, ^envelope} = FetchEnvelopeByExternalId.call(scope, book, envelope.external_id)
    end

    test "with commenter role (authorized scope) returns envelope", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      envelope = %Envelope{id: 1, name: "Commenter Envelope", category_id: category.id, external_id: Ecto.UUID.generate()}

      stub(EnvelopeRepository, :get_by_external_id_and_book_id, fn _external_id, _book_id, _opts ->
        envelope
      end)

      assert {:ok, ^envelope} = FetchEnvelopeByExternalId.call(scope, book, envelope.external_id)
    end

    test "with no association to book (unauthorized scope) returns error", %{book: book} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      external_id = Ecto.UUID.generate()

      assert {:error, :unauthorized} = FetchEnvelopeByExternalId.call(scope, book, external_id)
    end

    test "with envelope from different book returns not found", %{category: category} do
      different_book = CoreFactory.insert(:book)
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: different_book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      envelope = %Envelope{
        id: 1,
        name: "Different Book Envelope",
        category_id: category.id,
        external_id: Ecto.UUID.generate()
      }

      stub(EnvelopeRepository, :get_by_external_id_and_book_id, fn external_id, book_id, _opts ->
        assert external_id == envelope.external_id
        assert book_id == different_book.id
        nil
      end)

      assert {:error, :not_found} = FetchEnvelopeByExternalId.call(scope, different_book, envelope.external_id)
    end
  end
end
