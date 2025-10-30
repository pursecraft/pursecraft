defmodule PurseCraft.Accounting.Commands.Transactions.UpdateTransferTest do
  use PurseCraft.DataCase, async: true
  use Mimic
  use Oban.Testing, repo: PurseCraft.Repo

  alias PurseCraft.Accounting
  alias PurseCraft.Accounting.Commands.Transactions.UpdateTransfer
  alias PurseCraft.Accounting.Repositories.TransactionRepository
  alias PurseCraft.AccountingFactory
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.IdentityFactory
  alias PurseCraft.Search.Workers.GenerateTokensWorker
  alias PurseCraft.TestHelpers.PositionHelper

  setup do
    workspace = CoreFactory.insert(:workspace)
    user = IdentityFactory.insert(:user)
    CoreFactory.insert(:workspace_user, workspace_id: workspace.id, user_id: user.id, role: :owner)
    scope = IdentityFactory.build(:scope, user: user)

    %{user: user, workspace: workspace, scope: scope}
  end

  describe "call/4 - happy path" do
    test "updates memo on both transactions", %{scope: scope, workspace: workspace} do
      {from_transaction, to_transaction} = create_transfer(scope, workspace)

      assert {:ok, {updated_from, updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 memo: "Updated transfer memo"
               })

      assert updated_from.memo == "Updated transfer memo"
      assert updated_to.memo == "Updated transfer memo"
      assert updated_from.id == from_transaction.id
      assert updated_to.id == to_transaction.id
      assert updated_from.linked_transaction_id == updated_to.id
      assert updated_to.linked_transaction_id == updated_from.id
    end

    test "updates cleared status on both transactions", %{scope: scope, workspace: workspace} do
      {from_transaction, to_transaction} = create_transfer(scope, workspace, %{cleared: false})

      assert {:ok, {updated_from, updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 cleared: true
               })

      assert updated_from.cleared == true
      assert updated_to.cleared == true
      assert updated_from.id == from_transaction.id
      assert updated_to.id == to_transaction.id
    end

    test "updates both memo and cleared together", %{scope: scope, workspace: workspace} do
      {from_transaction, _to_transaction} = create_transfer(scope, workspace, %{cleared: false})

      assert {:ok, {updated_from, updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 memo: "New memo",
                 cleared: true
               })

      assert updated_from.memo == "New memo"
      assert updated_to.memo == "New memo"
      assert updated_from.cleared == true
      assert updated_to.cleared == true
    end

    test "handles nil memo (removes memo)", %{scope: scope, workspace: workspace} do
      {from_transaction, _to_transaction} =
        create_transfer(scope, workspace, %{memo: "Original memo"})

      assert {:ok, {updated_from, updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{memo: nil})

      assert updated_from.memo == nil
      assert updated_to.memo == nil
    end

    test "maintains bidirectional linking after update", %{scope: scope, workspace: workspace} do
      {from_transaction, to_transaction} = create_transfer(scope, workspace)

      assert {:ok, {updated_from, updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 memo: "Updated"
               })

      assert updated_from.linked_transaction_id == to_transaction.id
      assert updated_to.linked_transaction_id == from_transaction.id
    end
  end

  describe "call/4 - transaction fetching" do
    test "accepts Transaction struct", %{scope: scope, workspace: workspace} do
      {from_transaction, _to_transaction} = create_transfer(scope, workspace)

      assert {:ok, {updated_from, _updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction, %{memo: "Via struct"})

      assert updated_from.memo == "Via struct"
    end

    test "accepts integer ID", %{scope: scope, workspace: workspace} do
      {from_transaction, _to_transaction} = create_transfer(scope, workspace)

      assert {:ok, {updated_from, _updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.id, %{memo: "Via ID"})

      assert updated_from.memo == "Via ID"
    end

    test "accepts UUID external_id", %{scope: scope, workspace: workspace} do
      {from_transaction, _to_transaction} = create_transfer(scope, workspace)

      assert {:ok, {updated_from, _updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 memo: "Via UUID"
               })

      assert updated_from.memo == "Via UUID"
    end
  end

  describe "call/4 - authorization" do
    test "owner can update transfer", %{user: user, workspace: workspace} do
      scope = build_scope_for(user, workspace, :owner)
      {from_transaction, _to_transaction} = create_transfer(scope, workspace)

      assert {:ok, {updated_from, _updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 memo: "Owner update"
               })

      assert updated_from.memo == "Owner update"
    end

    test "editor can update transfer", %{user: user, workspace: workspace} do
      scope = build_scope_for(user, workspace, :editor)
      owner_user = IdentityFactory.insert(:user)
      owner_scope = build_scope_for(owner_user, workspace, :owner)
      {from_transaction, _to_transaction} = create_transfer(owner_scope, workspace)

      assert {:ok, {updated_from, _updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 memo: "Editor update"
               })

      assert updated_from.memo == "Editor update"
    end

    test "commenter cannot update transfer", %{user: user, workspace: workspace} do
      scope = build_scope_for(user, workspace, :commenter)
      owner_user = IdentityFactory.insert(:user)
      owner_scope = build_scope_for(owner_user, workspace, :owner)
      {from_transaction, _to_transaction} = create_transfer(owner_scope, workspace)

      assert {:error, :unauthorized} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 memo: "Commenter update"
               })
    end

    test "user not in workspace cannot update", %{workspace: workspace} do
      other_user = IdentityFactory.insert(:user)
      other_workspace = CoreFactory.insert(:workspace)
      other_scope = build_scope_for(other_user, other_workspace, :owner)

      owner_user = IdentityFactory.insert(:user)
      owner_scope = build_scope_for(owner_user, workspace, :owner)
      {from_transaction, _to_transaction} = create_transfer(owner_scope, workspace)

      assert {:error, :unauthorized} =
               UpdateTransfer.call(other_scope, workspace, from_transaction.external_id, %{
                 memo: "Other user update"
               })
    end
  end

  describe "call/4 - transfer validation" do
    test "returns :not_a_transfer for regular transaction", %{scope: scope, workspace: workspace} do
      regular_transaction = create_regular_transaction(scope, workspace)

      assert {:error, :not_a_transfer} =
               UpdateTransfer.call(scope, workspace, regular_transaction.external_id, %{
                 memo: "Update"
               })
    end

    test "returns :not_a_transfer if linked transaction is deleted", %{
      scope: scope,
      workspace: workspace
    } do
      {from_transaction, to_transaction} = create_transfer(scope, workspace)

      # Delete the linked transaction (sets linked_transaction_id to NULL via on_delete: :nilify_all)
      TransactionRepository.delete(to_transaction)

      assert {:error, :not_a_transfer} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 memo: "Update"
               })
    end

    test "returns :not_found for invalid external_id", %{scope: scope, workspace: workspace} do
      assert {:error, :not_found} =
               UpdateTransfer.call(scope, workspace, Ecto.UUID.generate(), %{memo: "Update"})
    end
  end

  describe "call/4 - immutable field protection" do
    test "allows amount changes with correct signs", %{scope: scope, workspace: workspace} do
      from_account =
        AccountingFactory.insert(:account,
          workspace: workspace,
          account_type: "checking",
          position: PositionHelper.generate_lowercase_position()
        )

      to_account =
        AccountingFactory.insert(:account,
          workspace: workspace,
          account_type: "savings",
          position: PositionHelper.generate_lowercase_position()
        )

      {from_transaction, _to_transaction} =
        create_transfer(scope, workspace, %{from_account: from_account, to_account: to_account})

      assert {:ok, {updated_from, updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 amount: 50_000
               })

      assert abs(updated_from.amount) == 50_000
      assert abs(updated_to.amount) == 50_000
      assert updated_from.amount + updated_to.amount == 0
    end

    test "allows date changes", %{scope: scope, workspace: workspace} do
      {from_transaction, _to_transaction} = create_transfer(scope, workspace)

      assert {:ok, {updated_from, updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 date: ~D[2025-01-01]
               })

      assert updated_from.date == ~D[2025-01-01]
      assert updated_to.date == ~D[2025-01-01]
    end

    test "silently ignores account_id changes", %{scope: scope, workspace: workspace} do
      {from_transaction, _to_transaction} = create_transfer(scope, workspace)
      original_account_id = from_transaction.account_id

      # Repository silently drops account_id from attrs
      assert {:ok, {updated_from, _updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 account_id: 999
               })

      # account_id should remain unchanged
      assert updated_from.account_id == original_account_id
    end

    test "silently ignores workspace_id changes", %{scope: scope, workspace: workspace} do
      {from_transaction, _to_transaction} = create_transfer(scope, workspace)
      original_workspace_id = from_transaction.workspace_id

      # Repository silently drops workspace_id from attrs
      assert {:ok, {updated_from, _updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 workspace_id: 999
               })

      # workspace_id should remain unchanged
      assert updated_from.workspace_id == original_workspace_id
    end
  end

  describe "call/4 - atomicity" do
    setup :set_mimic_global

    test "updates both transactions in the same database transaction", %{
      scope: scope,
      workspace: workspace
    } do
      {from_transaction, to_transaction} = create_transfer(scope, workspace)

      # Verify both transactions are updated atomically
      assert {:ok, {updated_from, updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 memo: "Atomic update"
               })

      # Both should have the same memo
      assert updated_from.memo == "Atomic update"
      assert updated_to.memo == "Atomic update"

      # Verify in database
      reloaded_from = TransactionRepository.get_by_id(from_transaction.id)
      reloaded_to = TransactionRepository.get_by_id(to_transaction.id)

      assert reloaded_from.memo == "Atomic update"
      assert reloaded_to.memo == "Atomic update"
    end

    test "maintains data integrity when update fails", %{scope: scope, workspace: workspace} do
      {from_transaction, _to_transaction} = create_transfer(scope, workspace)

      # Try to update with invalid data - use an invalid date
      assert {:error, _changeset} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 date: nil
               })

      # Verify the transaction wasn't modified
      reloaded = TransactionRepository.get_by_id(from_transaction.id)
      assert reloaded.date == from_transaction.date
    end
  end

  describe "call/4 - search token generation" do
    test "schedules tokens for both when memo changes", %{scope: scope, workspace: workspace} do
      {from_transaction, _to_transaction} =
        create_transfer(scope, workspace, %{memo: "Original"})

      assert {:ok, {_updated_from, _updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 memo: "Changed memo"
               })

      # Verify worker was enqueued (would need Oban.Testing helpers for thorough check)
      # For now, just verify the call succeeded
      assert_enqueued(worker: GenerateTokensWorker)
    end

    test "does not schedule tokens when only cleared changes", %{
      scope: scope,
      workspace: workspace
    } do
      {from_transaction, _to_transaction} =
        create_transfer(scope, workspace, %{memo: "Original", cleared: false})

      # Get current job count
      initial_jobs = all_enqueued(worker: GenerateTokensWorker)
      initial_count = length(initial_jobs)

      assert {:ok, {_updated_from, _updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 cleared: true
               })

      # Verify no new jobs were enqueued
      final_jobs = all_enqueued(worker: GenerateTokensWorker)
      final_count = length(final_jobs)

      assert final_count == initial_count, "Expected no new jobs, but #{final_count - initial_count} were added"
    end

    test "schedules tokens when memo set to nil", %{scope: scope, workspace: workspace} do
      {from_transaction, _to_transaction} =
        create_transfer(scope, workspace, %{memo: "Original"})

      assert {:ok, {_updated_from, _updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{memo: nil})

      assert_enqueued(worker: GenerateTokensWorker)
    end

    test "does not schedule tokens when memo changes to empty string", %{
      scope: scope,
      workspace: workspace
    } do
      {from_transaction, _to_transaction} =
        create_transfer(scope, workspace, %{memo: "Original"})

      # Get current job count
      initial_jobs = all_enqueued(worker: GenerateTokensWorker)
      initial_count = length(initial_jobs)

      assert {:ok, {updated_from, _updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{memo: ""})

      # Verify no new jobs were enqueued (empty string becomes nil, no searchable fields)
      final_jobs = all_enqueued(worker: GenerateTokensWorker)
      final_count = length(final_jobs)

      # Memo changed to nil (empty string converted), but no searchable fields so no jobs scheduled
      assert updated_from.memo == nil

      assert final_count == initial_count,
             "Expected no new jobs for empty memo, but #{final_count - initial_count} were added"
    end
  end

  describe "call/4 - PubSub broadcasting" do
    test "broadcasts :transaction_updated for both transactions", %{
      scope: scope,
      workspace: workspace
    } do
      {from_transaction, _to_transaction} = create_transfer(scope, workspace)

      PurseCraft.PubSub.subscribe_workspace(workspace)

      assert {:ok, {updated_from, updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 memo: "Broadcast test"
               })

      # Verify we received both broadcasts
      assert_received {:transaction_updated, ^updated_from}
      assert_received {:transaction_updated, ^updated_to}
    end

    test "broadcasts even when no actual changes occur", %{scope: scope, workspace: workspace} do
      {from_transaction, _to_transaction} =
        create_transfer(scope, workspace, %{memo: "Same memo"})

      PurseCraft.PubSub.subscribe_workspace(workspace)

      assert {:ok, {updated_from, updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 memo: "Same memo"
               })

      # Verify broadcasts still happened
      assert_received {:transaction_updated, ^updated_from}
      assert_received {:transaction_updated, ^updated_to}
    end
  end

  describe "call/4 - edge cases" do
    test "handles very long memos", %{scope: scope, workspace: workspace} do
      {from_transaction, _to_transaction} = create_transfer(scope, workspace)

      long_memo = String.duplicate("a", 1000)

      assert {:ok, {updated_from, updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 memo: long_memo
               })

      assert updated_from.memo == long_memo
      assert updated_to.memo == long_memo
    end

    test "handles special characters in memo", %{scope: scope, workspace: workspace} do
      {from_transaction, _to_transaction} = create_transfer(scope, workspace)

      special_memo = "émojis 💰 and spëcial çhars!"

      assert {:ok, {updated_from, updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 memo: special_memo
               })

      assert updated_from.memo == special_memo
      assert updated_to.memo == special_memo
    end

    test "works with transfers between same account type", %{scope: scope, workspace: workspace} do
      from_account =
        AccountingFactory.insert(:account,
          workspace: workspace,
          account_type: "checking",
          position: PositionHelper.generate_lowercase_position()
        )

      to_account =
        AccountingFactory.insert(:account,
          workspace: workspace,
          account_type: "checking",
          position: PositionHelper.generate_lowercase_position()
        )

      {:ok, {from_transaction, _to_transaction}} =
        Accounting.create_transfer(scope, workspace, %{
          from_account: from_account,
          to_account: to_account,
          amount: 10_000,
          memo: "Between checking accounts"
        })

      assert {:ok, {updated_from, updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 memo: "Updated checking transfer"
               })

      assert updated_from.memo == "Updated checking transfer"
      assert updated_to.memo == "Updated checking transfer"
    end

    test "works with asset-to-liability transfers", %{scope: scope, workspace: workspace} do
      from_account =
        AccountingFactory.insert(:account,
          workspace: workspace,
          account_type: "checking",
          position: PositionHelper.generate_lowercase_position()
        )

      to_account =
        AccountingFactory.insert(:account,
          workspace: workspace,
          account_type: "credit_card",
          position: PositionHelper.generate_lowercase_position()
        )

      {:ok, {from_transaction, _to_transaction}} =
        Accounting.create_transfer(scope, workspace, %{
          from_account: from_account,
          to_account: to_account,
          amount: 10_000,
          memo: "Pay credit card"
        })

      assert {:ok, {updated_from, updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 cleared: true
               })

      assert updated_from.cleared == true
      assert updated_to.cleared == true
      # Verify amounts didn't change
      assert updated_from.amount == -10_000
      assert updated_to.amount == -10_000
    end

    test "works with liability-to-asset transfers", %{scope: scope, workspace: workspace} do
      from_account =
        AccountingFactory.insert(:account,
          workspace: workspace,
          account_type: "credit_card",
          position: PositionHelper.generate_lowercase_position()
        )

      to_account =
        AccountingFactory.insert(:account,
          workspace: workspace,
          account_type: "checking",
          position: PositionHelper.generate_lowercase_position()
        )

      {:ok, {from_transaction, _to_transaction}} =
        Accounting.create_transfer(scope, workspace, %{
          from_account: from_account,
          to_account: to_account,
          amount: 10_000,
          memo: "Cash advance"
        })

      assert {:ok, {updated_from, updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 memo: "Updated cash advance"
               })

      assert updated_from.memo == "Updated cash advance"
      assert updated_to.memo == "Updated cash advance"
      # Verify amounts didn't change
      assert updated_from.amount == 10_000
      assert updated_to.amount == 10_000
    end

    test "works with liability-to-liability transfers", %{scope: scope, workspace: workspace} do
      from_account =
        AccountingFactory.insert(:account,
          workspace: workspace,
          account_type: "credit_card",
          position: PositionHelper.generate_lowercase_position()
        )

      to_account =
        AccountingFactory.insert(:account,
          workspace: workspace,
          account_type: "credit_card",
          position: PositionHelper.generate_lowercase_position()
        )

      {:ok, {from_transaction, _to_transaction}} =
        Accounting.create_transfer(scope, workspace, %{
          from_account: from_account,
          to_account: to_account,
          amount: 10_000,
          memo: "Balance transfer"
        })

      assert {:ok, {updated_from, updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 memo: "Updated balance transfer"
               })

      assert updated_from.memo == "Updated balance transfer"
      assert updated_to.memo == "Updated balance transfer"
      # Verify amounts didn't change
      assert updated_from.amount == 10_000
      assert updated_to.amount == -10_000
    end

    test "handles multiple rapid updates", %{scope: scope, workspace: workspace} do
      {from_transaction, _to_transaction} = create_transfer(scope, workspace)

      # First update
      assert {:ok, {updated_from, _updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 memo: "First"
               })

      assert updated_from.memo == "First"

      # Second update
      assert {:ok, {updated_from, _updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 memo: "Second"
               })

      assert updated_from.memo == "Second"

      # Third update
      assert {:ok, {updated_from, _updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 memo: "Third"
               })

      assert updated_from.memo == "Third"
    end
  end

  describe "call/4 - preloading" do
    test "returns transactions with transaction_lines preloaded", %{
      scope: scope,
      workspace: workspace
    } do
      {from_transaction, _to_transaction} = create_transfer(scope, workspace)

      assert {:ok, {updated_from, updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 memo: "Preload test"
               })

      # Verify associations are preloaded (not %Ecto.Association.NotLoaded{})
      assert is_list(updated_from.transaction_lines)
      assert is_list(updated_to.transaction_lines)
      assert length(updated_from.transaction_lines) == 1
      assert length(updated_to.transaction_lines) == 1
    end

    test "maintains line associations after update", %{scope: scope, workspace: workspace} do
      {from_transaction, to_transaction} = create_transfer(scope, workspace)

      [original_from_line] = from_transaction.transaction_lines
      [original_to_line] = to_transaction.transaction_lines

      assert {:ok, {updated_from, updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 cleared: true
               })

      [updated_from_line] = updated_from.transaction_lines
      [updated_to_line] = updated_to.transaction_lines

      # Verify lines are the same (not recreated)
      assert updated_from_line.id == original_from_line.id
      assert updated_to_line.id == original_to_line.id
    end
  end

  describe "context API integration" do
    test "can be called through Accounting.update_transfer/4", %{
      scope: scope,
      workspace: workspace
    } do
      {from_transaction, _to_transaction} = create_transfer(scope, workspace)

      assert {:ok, {updated_from, _updated_to}} =
               Accounting.update_transfer(scope, workspace, from_transaction.external_id, %{
                 memo: "Via context API"
               })

      assert updated_from.memo == "Via context API"
    end

    test "accepts string keys in attrs", %{scope: scope, workspace: workspace} do
      {from_transaction, _to_transaction} = create_transfer(scope, workspace)

      # Pass string keys instead of atoms
      assert {:ok, {updated_from, _updated_to}} =
               UpdateTransfer.call(scope, workspace, from_transaction.external_id, %{
                 "memo" => "String key memo",
                 "cleared" => true
               })

      assert updated_from.memo == "String key memo"
      assert updated_from.cleared == true
    end
  end

  # Helper functions

  defp create_transfer(scope, workspace, attrs \\ %{}) do
    # Use generate_lowercase_position/0 for unique positions in async tests
    from_account =
      AccountingFactory.insert(:account, workspace: workspace, position: PositionHelper.generate_lowercase_position())

    to_account =
      AccountingFactory.insert(:account, workspace: workspace, position: PositionHelper.generate_lowercase_position())

    default_attrs = %{
      from_account: from_account,
      to_account: to_account,
      amount: 10_000,
      memo: "Test transfer"
    }

    attrs = Map.merge(default_attrs, attrs)

    {:ok, {from_transaction, to_transaction}} =
      Accounting.create_transfer(scope, workspace, attrs)

    {from_transaction, to_transaction}
  end

  defp create_regular_transaction(scope, workspace) do
    account = AccountingFactory.insert(:account, workspace: workspace)
    category = BudgetingFactory.insert(:category, workspace: workspace)
    envelope = BudgetingFactory.insert(:envelope, category_id: category.id)

    {:ok, transaction} =
      Accounting.create_transaction(scope, workspace, %{
        source: account,
        destination: envelope,
        amount: 5_000,
        memo: "Regular transaction"
      })

    transaction
  end

  defp build_scope_for(user, workspace, role) do
    # Insert or update workspace_user with the specified role
    workspace_user =
      PurseCraft.Repo.get_by(PurseCraft.Core.Schemas.WorkspaceUser,
        user_id: user.id,
        workspace_id: workspace.id
      )

    case workspace_user do
      nil ->
        CoreFactory.insert(:workspace_user, user: user, workspace: workspace, role: role)

      existing ->
        existing
        |> Ecto.Changeset.change(role: role)
        |> PurseCraft.Repo.update!()
    end

    IdentityFactory.build(:scope, user: user)
  end
end
