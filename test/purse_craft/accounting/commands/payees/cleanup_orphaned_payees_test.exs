defmodule PurseCraft.Accounting.Commands.Payees.CleanupOrphanedPayeesTest do
  use PurseCraft.DataCase, async: true

  import Ecto.Query

  alias PurseCraft.Accounting.Commands.Payees.CleanupOrphanedPayees
  alias PurseCraft.Accounting.Repositories.PayeeRepository
  alias PurseCraft.AccountingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.Repo

  setup do
    workspace = CoreFactory.insert(:workspace)
    {:ok, workspace: workspace}
  end

  describe "call/1" do
    test "deletes all orphaned payees", %{workspace: workspace} do
      orphaned1 = AccountingFactory.insert(:payee, workspace_id: workspace.id)
      orphaned2 = AccountingFactory.insert(:payee, workspace_id: workspace.id)
      orphaned3 = AccountingFactory.insert(:payee, workspace_id: workspace.id)

      assert {:ok, 3} = CleanupOrphanedPayees.call(workspace)

      assert PayeeRepository.get_by_external_id(orphaned1.external_id) == nil
      assert PayeeRepository.get_by_external_id(orphaned2.external_id) == nil
      assert PayeeRepository.get_by_external_id(orphaned3.external_id) == nil
    end

    test "does not delete payees referenced by transactions", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace)
      orphaned = AccountingFactory.insert(:payee, workspace_id: workspace.id)
      referenced = AccountingFactory.insert(:payee, workspace_id: workspace.id)

      AccountingFactory.insert(:transaction,
        workspace_id: workspace.id,
        account_id: account.id,
        payee_id: referenced.id
      )

      assert {:ok, 1} = CleanupOrphanedPayees.call(workspace)

      assert PayeeRepository.get_by_external_id(orphaned.external_id) == nil
      assert PayeeRepository.get_by_external_id(referenced.external_id) != nil
    end

    test "does not delete payees referenced by transaction_lines", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace)
      orphaned = AccountingFactory.insert(:payee, workspace_id: workspace.id)
      line_referenced = AccountingFactory.insert(:payee, workspace_id: workspace.id)

      transaction =
        AccountingFactory.insert(:transaction,
          workspace_id: workspace.id,
          account_id: account.id
        )

      AccountingFactory.insert(:transaction_line,
        transaction_id: transaction.id,
        payee_id: line_referenced.id
      )

      assert {:ok, 1} = CleanupOrphanedPayees.call(workspace)

      assert PayeeRepository.get_by_external_id(orphaned.external_id) == nil
      assert PayeeRepository.get_by_external_id(line_referenced.external_id) != nil
    end

    test "returns zero when no orphaned payees exist", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace)
      referenced = AccountingFactory.insert(:payee, workspace_id: workspace.id)

      AccountingFactory.insert(:transaction,
        workspace_id: workspace.id,
        account_id: account.id,
        payee_id: referenced.id
      )

      assert {:ok, 0} = CleanupOrphanedPayees.call(workspace)
      assert PayeeRepository.get_by_external_id(referenced.external_id) != nil
    end

    test "returns zero when workspace has no payees", %{workspace: workspace} do
      assert {:ok, 0} = CleanupOrphanedPayees.call(workspace)
    end

    test "schedules search token deletion for deleted payees", %{workspace: workspace} do
      orphaned1 = AccountingFactory.insert(:payee, workspace_id: workspace.id)
      orphaned2 = AccountingFactory.insert(:payee, workspace_id: workspace.id)

      assert {:ok, 2} = CleanupOrphanedPayees.call(workspace)

      query =
        from(j in Oban.Job,
          where: j.worker == "PurseCraft.Search.Workers.DeleteTokensWorker",
          where: j.state == "available"
        )

      jobs = Repo.all(query)

      assert length(jobs) == 2

      job_args = Enum.map(jobs, & &1.args)
      assert %{"entity_type" => "payee", "entity_id" => orphaned1.id} in job_args
      assert %{"entity_type" => "payee", "entity_id" => orphaned2.id} in job_args
    end

    test "does not schedule token deletion when no payees deleted", %{workspace: workspace} do
      account = AccountingFactory.insert(:account, workspace: workspace)
      referenced = AccountingFactory.insert(:payee, workspace_id: workspace.id)

      AccountingFactory.insert(:transaction,
        workspace_id: workspace.id,
        account_id: account.id,
        payee_id: referenced.id
      )

      assert {:ok, 0} = CleanupOrphanedPayees.call(workspace)

      query =
        from(j in Oban.Job,
          where: j.worker == "PurseCraft.Search.Workers.DeleteTokensWorker",
          where: j.state == "available"
        )

      jobs = Repo.all(query)

      assert jobs == []
    end

    test "works with payees referenced by both transactions and transaction_lines", %{
      workspace: workspace
    } do
      account = AccountingFactory.insert(:account, workspace: workspace)
      orphaned = AccountingFactory.insert(:payee, workspace_id: workspace.id)
      dual_referenced = AccountingFactory.insert(:payee, workspace_id: workspace.id)

      transaction =
        AccountingFactory.insert(:transaction,
          workspace_id: workspace.id,
          account_id: account.id,
          payee_id: dual_referenced.id
        )

      AccountingFactory.insert(:transaction_line,
        transaction_id: transaction.id,
        payee_id: dual_referenced.id
      )

      assert {:ok, 1} = CleanupOrphanedPayees.call(workspace)

      assert PayeeRepository.get_by_external_id(orphaned.external_id) == nil
      assert PayeeRepository.get_by_external_id(dual_referenced.external_id) != nil
    end

    test "only affects specified workspace", %{workspace: workspace} do
      other_workspace = CoreFactory.insert(:workspace)

      orphaned_ws1 = AccountingFactory.insert(:payee, workspace_id: workspace.id)
      orphaned_ws2 = AccountingFactory.insert(:payee, workspace_id: other_workspace.id)

      assert {:ok, 1} = CleanupOrphanedPayees.call(workspace)

      assert PayeeRepository.get_by_external_id(orphaned_ws1.external_id) == nil
      assert PayeeRepository.get_by_external_id(orphaned_ws2.external_id) != nil
    end
  end
end
