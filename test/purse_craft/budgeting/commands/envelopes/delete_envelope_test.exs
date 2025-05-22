defmodule PurseCraft.Budgeting.Commands.Envelopes.DeleteEnvelopeTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Envelopes.DeleteEnvelope
  alias PurseCraft.Budgeting.Commands.PubSub.BroadcastBook
  alias PurseCraft.Budgeting.Repositories.EnvelopeRepository
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.IdentityFactory

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

  describe "call/3" do
    test "with owner role (authorized scope) deletes an envelope", %{book: book, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      stub(EnvelopeRepository, :delete, fn ^envelope ->
        {:ok, envelope}
      end)

      assert {:ok, ^envelope} = DeleteEnvelope.call(scope, book, envelope)
    end

    test "with editor role (authorized scope) deletes an envelope", %{book: book, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      stub(EnvelopeRepository, :delete, fn ^envelope ->
        {:ok, envelope}
      end)

      assert {:ok, ^envelope} = DeleteEnvelope.call(scope, book, envelope)
    end

    test "with commenter role (unauthorized scope) returns error", %{book: book, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = DeleteEnvelope.call(scope, book, envelope)
    end

    test "with no association to book (unauthorized scope) returns error", %{book: book, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} = DeleteEnvelope.call(scope, book, envelope)
    end

    test "with database error returns error changeset", %{book: book, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      changeset = %Ecto.Changeset{valid?: false}

      stub(EnvelopeRepository, :delete, fn ^envelope ->
        {:error, changeset}
      end)

      assert {:error, ^changeset} = DeleteEnvelope.call(scope, book, envelope)
    end

    test "invokes BroadcastBook when envelope is deleted successfully", %{book: book, envelope: envelope} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      stub(EnvelopeRepository, :delete, fn ^envelope -> {:ok, envelope} end)

      expect(BroadcastBook, :call, fn ^book, {:envelope_deleted, ^envelope} -> :ok end)

      assert {:ok, ^envelope} = DeleteEnvelope.call(scope, book, envelope)

      verify!()
    end
  end
end
