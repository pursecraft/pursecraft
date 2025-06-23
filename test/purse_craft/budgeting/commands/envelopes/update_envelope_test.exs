defmodule PurseCraft.Budgeting.Commands.Envelopes.UpdateEnvelopeTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Envelopes.UpdateEnvelope
  alias PurseCraft.Budgeting.Repositories.EnvelopeRepository
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastBook

  setup do
    book = BudgetingFactory.insert(:book)
    category = BudgetingFactory.insert(:category, book_id: book.id)
    envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

    %{
      book: book,
      category: category,
      envelope: envelope
    }
  end

  describe "call/4" do
    test "with string keys in attrs updates an envelope correctly", %{book: book, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      updated_envelope = %{envelope | name: "String Key Updated Envelope"}

      stub(EnvelopeRepository, :update, fn ^envelope, attrs ->
        assert attrs.name == "String Key Updated Envelope"
        {:ok, updated_envelope}
      end)

      attrs = %{"name" => "String Key Updated Envelope"}

      assert {:ok, ^updated_envelope} = UpdateEnvelope.call(scope, book, envelope, attrs)
    end

    test "with invalid data returns error changeset", %{book: book, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      changeset = %Ecto.Changeset{valid?: false}

      stub(EnvelopeRepository, :update, fn ^envelope, _attrs ->
        {:error, changeset}
      end)

      attrs = %{name: ""}

      assert {:error, ^changeset} = UpdateEnvelope.call(scope, book, envelope, attrs)
    end

    test "with owner role (authorized scope) updates an envelope", %{book: book, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      updated_envelope = %{envelope | name: "Owner Updated Envelope"}

      stub(EnvelopeRepository, :update, fn ^envelope, attrs ->
        assert attrs.name == "Owner Updated Envelope"
        {:ok, updated_envelope}
      end)

      attrs = %{name: "Owner Updated Envelope"}

      assert {:ok, ^updated_envelope} = UpdateEnvelope.call(scope, book, envelope, attrs)
    end

    test "with editor role (authorized scope) updates an envelope", %{book: book, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      updated_envelope = %{envelope | name: "Editor Updated Envelope"}

      stub(EnvelopeRepository, :update, fn ^envelope, attrs ->
        assert attrs.name == "Editor Updated Envelope"
        {:ok, updated_envelope}
      end)

      attrs = %{name: "Editor Updated Envelope"}

      assert {:ok, ^updated_envelope} = UpdateEnvelope.call(scope, book, envelope, attrs)
    end

    test "with commenter role (unauthorized scope) returns error", %{book: book, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Commenter Updated Envelope"}

      assert {:error, :unauthorized} = UpdateEnvelope.call(scope, book, envelope, attrs)
    end

    test "with no association to book (unauthorized scope) returns error", %{book: book, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Unauthorized Updated Envelope"}

      assert {:error, :unauthorized} = UpdateEnvelope.call(scope, book, envelope, attrs)
    end

    test "invokes BroadcastBook when envelope is updated successfully", %{book: book, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      updated_envelope = %{envelope | name: "Broadcast Test Updated Envelope"}

      stub(EnvelopeRepository, :update, fn ^envelope, _attrs -> {:ok, updated_envelope} end)

      expect(BroadcastBook, :call, fn ^book, {:envelope_updated, ^updated_envelope} -> :ok end)

      attrs = %{name: "Broadcast Test Updated Envelope"}

      assert {:ok, ^updated_envelope} = UpdateEnvelope.call(scope, book, envelope, attrs)

      verify!()
    end
  end
end
