defmodule PurseCraft.Budgeting.Commands.Envelopes.CreateEnvelopeTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Envelopes.CreateEnvelope
  alias PurseCraft.Budgeting.Repositories.EnvelopeRepository
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastBook

  setup do
    book = CoreFactory.insert(:book)
    category = BudgetingFactory.insert(:category, book_id: book.id)

    %{
      book: book,
      category: category
    }
  end

  describe "call/4" do
    test "with string keys in attrs creates an envelope correctly", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      envelope = %Envelope{id: 1, name: "String Key Envelope", category_id: category.id}

      stub(EnvelopeRepository, :get_first_position, fn _category_id -> nil end)

      stub(EnvelopeRepository, :create, fn attrs ->
        assert attrs.name == "String Key Envelope"
        assert attrs.category_id == category.id
        assert attrs.position == "m"
        {:ok, envelope}
      end)

      attrs = %{"name" => "String Key Envelope"}

      assert {:ok, ^envelope} = CreateEnvelope.call(scope, book, category, attrs)
    end

    test "with invalid data returns error changeset", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      changeset = %Ecto.Changeset{valid?: false}

      stub(EnvelopeRepository, :get_first_position, fn _category_id -> nil end)

      stub(EnvelopeRepository, :create, fn _attrs ->
        {:error, changeset}
      end)

      attrs = %{name: ""}

      assert {:error, ^changeset} = CreateEnvelope.call(scope, book, category, attrs)
    end

    test "with owner role (authorized scope) creates an envelope", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      envelope = %Envelope{id: 1, name: "Owner Envelope", category_id: category.id}

      stub(EnvelopeRepository, :get_first_position, fn _category_id -> nil end)

      stub(EnvelopeRepository, :create, fn attrs ->
        assert attrs.name == "Owner Envelope"
        assert attrs.category_id == category.id
        assert attrs.position == "m"
        {:ok, envelope}
      end)

      attrs = %{name: "Owner Envelope"}

      assert {:ok, ^envelope} = CreateEnvelope.call(scope, book, category, attrs)
    end

    test "with editor role (authorized scope) creates an envelope", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :editor)
      scope = IdentityFactory.build(:scope, user: user)

      envelope = %Envelope{id: 1, name: "Editor Envelope", category_id: category.id}

      stub(EnvelopeRepository, :get_first_position, fn _category_id -> nil end)

      stub(EnvelopeRepository, :create, fn attrs ->
        assert attrs.name == "Editor Envelope"
        assert attrs.category_id == category.id
        assert attrs.position == "m"
        {:ok, envelope}
      end)

      attrs = %{name: "Editor Envelope"}

      assert {:ok, ^envelope} = CreateEnvelope.call(scope, book, category, attrs)
    end

    test "with commenter role (unauthorized scope) returns error", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
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
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      envelope = %Envelope{id: 1, name: "Broadcast Test Envelope", category_id: category.id}

      stub(EnvelopeRepository, :get_first_position, fn _category_id -> nil end)

      stub(EnvelopeRepository, :create, fn _attrs -> {:ok, envelope} end)

      expect(BroadcastBook, :call, fn ^book, {:envelope_created, ^envelope} -> :ok end)

      attrs = %{name: "Broadcast Test Envelope"}

      assert {:ok, ^envelope} = CreateEnvelope.call(scope, book, category, attrs)

      verify!()
    end

    test "assigns position before existing envelope", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      envelope = %Envelope{id: 1, name: "New Envelope", category_id: category.id}

      stub(EnvelopeRepository, :get_first_position, fn _category_id -> "m" end)

      stub(EnvelopeRepository, :create, fn attrs ->
        assert attrs.position == "g"
        {:ok, envelope}
      end)

      attrs = %{name: "New Envelope"}

      assert {:ok, ^envelope} = CreateEnvelope.call(scope, book, category, attrs)
    end

    test "returns error when cannot place at top", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      stub(EnvelopeRepository, :get_first_position, fn _category_id -> "a" end)

      attrs = %{name: "New Envelope"}

      assert {:error, :cannot_place_at_top} = CreateEnvelope.call(scope, book, category, attrs)
    end
  end
end
