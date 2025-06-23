defmodule PurseCraft.Budgeting.Commands.Envelopes.RepositionEnvelopeTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Budgeting.Commands.Envelopes.RepositionEnvelope
  alias PurseCraft.Budgeting.Repositories.EnvelopeRepository
  alias PurseCraft.Budgeting.Schemas.Envelope
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.PubSub.BroadcastCategory

  setup do
    book = CoreFactory.insert(:book)
    category = BudgetingFactory.insert(:category, book: book, position: "c")
    target_category = BudgetingFactory.insert(:category, book: book, position: "s")

    env1 = BudgetingFactory.insert(:envelope, category: category, position: "g")
    env2 = BudgetingFactory.insert(:envelope, category: category, position: "m")
    env3 = BudgetingFactory.insert(:envelope, category: category, position: "t")

    %{
      book: book,
      category: category,
      target_category: target_category,
      env1: env1,
      env2: env2,
      env3: env3
    }
  end

  describe "call/5" do
    test "successfully repositions envelope within same category", %{
      book: book,
      category: category,
      env1: env1,
      env2: env2,
      env3: env3
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, updated} =
               RepositionEnvelope.call(scope, env3.external_id, category.external_id, env1.external_id, env2.external_id)

      assert updated.id == env3.id
      assert updated.position > env1.position
      assert updated.position < env2.position
      assert updated.category_id == category.id
    end

    test "successfully moves envelope to different category", %{book: book, target_category: target_category, env1: env1} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, updated} = RepositionEnvelope.call(scope, env1.external_id, target_category.external_id, nil, nil)

      assert updated.id == env1.id
      assert updated.category_id == target_category.id
    end

    test "repositions envelope to the beginning when prev_envelope_id is nil", %{
      book: book,
      category: category,
      env1: env1,
      env3: env3
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, updated} =
               RepositionEnvelope.call(scope, env3.external_id, category.external_id, nil, env1.external_id)

      assert updated.id == env3.id
      assert updated.position < env1.position
    end

    test "repositions envelope to the end when next_envelope_id is nil", %{
      book: book,
      category: category,
      env1: env1,
      env3: env3
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, updated} =
               RepositionEnvelope.call(scope, env1.external_id, category.external_id, env3.external_id, nil)

      assert updated.id == env1.id
      assert updated.position > env3.position
    end

    test "returns not_found when envelope doesn't exist", %{book: book, category: category, env1: env1, env2: env2} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :not_found} =
               RepositionEnvelope.call(
                 scope,
                 Ecto.UUID.generate(),
                 category.external_id,
                 env1.external_id,
                 env2.external_id
               )
    end

    test "returns not_found when target category doesn't exist", %{env1: env1, env2: env2} do
      user = IdentityFactory.insert(:user)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :not_found} =
               RepositionEnvelope.call(scope, env1.external_id, Ecto.UUID.generate(), env1.external_id, env2.external_id)
    end

    test "returns not_found when prev_envelope doesn't exist", %{book: book, category: category, env1: env1, env2: env2} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :not_found} =
               RepositionEnvelope.call(
                 scope,
                 env1.external_id,
                 category.external_id,
                 Ecto.UUID.generate(),
                 env2.external_id
               )
    end

    test "returns not_found when next_envelope doesn't exist", %{book: book, category: category, env1: env1, env2: env2} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :not_found} =
               RepositionEnvelope.call(
                 scope,
                 env1.external_id,
                 category.external_id,
                 env2.external_id,
                 Ecto.UUID.generate()
               )
    end

    test "returns not_found when prev_envelope is from different category", %{
      book: book,
      category: category,
      target_category: target_category,
      env1: env1,
      env2: env2
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      other_env = BudgetingFactory.insert(:envelope, category: target_category, position: "a")

      assert {:error, :not_found} =
               RepositionEnvelope.call(
                 scope,
                 env1.external_id,
                 category.external_id,
                 other_env.external_id,
                 env2.external_id
               )
    end

    test "returns unauthorized when user lacks permission", %{
      book: book,
      category: category,
      env1: env1,
      env2: env2,
      env3: env3
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :commenter)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:error, :unauthorized} =
               RepositionEnvelope.call(scope, env3.external_id, category.external_id, env1.external_id, env2.external_id)
    end

    test "returns error when fractional indexing fails", %{book: book, category: category} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      env1 = BudgetingFactory.insert(:envelope, category: category, position: "z")
      env2 = BudgetingFactory.insert(:envelope, category: category, position: "a")
      env3 = BudgetingFactory.insert(:envelope, category: category, position: "n")

      assert {:error, :prev_must_be_less_than_next} =
               RepositionEnvelope.call(scope, env3.external_id, category.external_id, env1.external_id, env2.external_id)
    end

    test "broadcasts envelope_repositioned event on success", %{
      book: book,
      category: category,
      env1: env1,
      env2: env2,
      env3: env3
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      expect(BroadcastCategory, :call, fn received_category, {:envelope_repositioned, received_envelope} ->
        assert received_category.id == category.id
        assert received_envelope.id == env3.id
        :ok
      end)

      assert {:ok, _updated} =
               RepositionEnvelope.call(scope, env3.external_id, category.external_id, env1.external_id, env2.external_id)

      verify!()
    end

    test "broadcasts envelope_removed event when moved between categories", %{
      book: book,
      category: category,
      target_category: target_category,
      env1: env1
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      expect(BroadcastCategory, :call, 2, fn
        received_category, {:envelope_repositioned, received_envelope} ->
          assert received_category.id == target_category.id
          assert received_envelope.id == env1.id
          :ok

        received_category, {:envelope_removed, received_envelope} ->
          assert received_category.id == category.id
          assert received_envelope.id == env1.id
          :ok
      end)

      assert {:ok, _updated} = RepositionEnvelope.call(scope, env1.external_id, target_category.external_id, nil, nil)

      verify!()
    end

    test "handles unique constraint violation with retry", %{
      book: book,
      category: category,
      env1: env1,
      env2: env2,
      env3: env3
    } do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      assert {:ok, updated} =
               RepositionEnvelope.call(scope, env3.external_id, category.external_id, env1.external_id, env2.external_id)

      assert updated.id == env3.id
      assert updated.position > env1.position
      assert updated.position < env2.position
    end

    test "returns error after max retries", %{book: book, category: category, env1: env1, env2: env2, env3: env3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      stub(EnvelopeRepository, :update_position, fn _envelope, _position, _category_id ->
        changeset = Envelope.position_changeset(env3, %{position: "test"})
        changeset = Ecto.Changeset.add_error(changeset, :position, "has already been taken")
        {:error, changeset}
      end)

      assert {:error, changeset} =
               RepositionEnvelope.call(scope, env3.external_id, category.external_id, env1.external_id, env2.external_id)

      assert Enum.any?(changeset.errors, fn
               {:position, {"has already been taken", _opts}} -> true
               _error -> false
             end)
    end

    test "handles non-position errors in changeset", %{book: book, category: category, env1: env1, env2: env2, env3: env3} do
      user = IdentityFactory.insert(:user)
      CoreFactory.insert(:book_user, book_id: book.id, user_id: user.id, role: :owner)
      scope = IdentityFactory.build(:scope, user: user)

      stub(EnvelopeRepository, :update_position, fn _envelope, _position, _category_id ->
        changeset = Envelope.position_changeset(env3, %{position: "test"})
        changeset = Ecto.Changeset.add_error(changeset, :name, "is invalid")
        {:error, changeset}
      end)

      assert {:error, changeset} =
               RepositionEnvelope.call(scope, env3.external_id, category.external_id, env1.external_id, env2.external_id)

      refute Enum.any?(changeset.errors, fn
               {:position, {"has already been taken", _opts}} -> true
               _error -> false
             end)
    end
  end
end
