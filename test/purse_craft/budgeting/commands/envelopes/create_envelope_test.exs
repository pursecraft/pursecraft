defmodule PurseCraft.Budgeting.Commands.Envelopes.CreateEnvelopeTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Envelopes.CreateEnvelope
  alias PurseCraft.Budgeting.Commands.PubSub.BroadcastBook
  alias PurseCraft.Budgeting.Repositories.EnvelopeRepository
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.IdentityFactory

  setup do
    book = BudgetingFactory.insert(:book)
    category = BudgetingFactory.insert(:category, book_id: book.id)

    %{
      book: book,
      category: category
    }
  end

  describe "call/4" do
    test "with string keys in attrs creates an envelope correctly", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      envelope = %Envelope{id: 1, name: "String Key Envelope", category_id: category.id}

      stub(EnvelopeRepository, :create, fn attrs ->
        assert attrs.name == "String Key Envelope"
        assert attrs.category_id == category.id
        {:ok, envelope}
      end)

      attrs = %{"name" => "String Key Envelope"}

      assert {:ok, ^envelope} = CreateEnvelope.call(scope, book, category, attrs)
    end

    test "with invalid data returns error changeset", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      changeset = %Ecto.Changeset{valid?: false}

      stub(EnvelopeRepository, :create, fn _attrs ->
        {:error, changeset}
      end)

      attrs = %{name: ""}

      assert {:error, ^changeset} = CreateEnvelope.call(scope, book, category, attrs)
    end

    test "with owner role (authorized scope) creates an envelope", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      envelope = %Envelope{id: 1, name: "Owner Envelope", category_id: category.id}

      stub(EnvelopeRepository, :create, fn attrs ->
        assert attrs.name == "Owner Envelope"
        assert attrs.category_id == category.id
        {:ok, envelope}
      end)

      attrs = %{name: "Owner Envelope"}

      assert {:ok, ^envelope} = CreateEnvelope.call(scope, book, category, attrs)
    end

    test "with editor role (authorized scope) creates an envelope", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      envelope = %Envelope{id: 1, name: "Editor Envelope", category_id: category.id}

      stub(EnvelopeRepository, :create, fn attrs ->
        assert attrs.name == "Editor Envelope"
        assert attrs.category_id == category.id
        {:ok, envelope}
      end)

      attrs = %{name: "Editor Envelope"}

      assert {:ok, ^envelope} = CreateEnvelope.call(scope, book, category, attrs)
    end

    test "with commenter role (unauthorized scope) returns error", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Commenter Envelope"}

      assert {:error, :unauthorized} = CreateEnvelope.call(scope, book, category, attrs)
    end

    test "with no association to book (unauthorized scope) returns error", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      attrs = %{name: "Unauthorized Envelope"}

      assert {:error, :unauthorized} = CreateEnvelope.call(scope, book, category, attrs)
    end

    test "invokes BroadcastBook when envelope is created successfully", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      BudgetingFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      envelope = %Envelope{id: 1, name: "Broadcast Test Envelope", category_id: category.id}

      stub(EnvelopeRepository, :create, fn _attrs -> {:ok, envelope} end)

      expect(BroadcastBook, :call, fn ^book, {:envelope_created, ^envelope} -> :ok end)

      attrs = %{name: "Broadcast Test Envelope"}

      assert {:ok, ^envelope} = CreateEnvelope.call(scope, book, category, attrs)

      verify!()
    end
  end
end
