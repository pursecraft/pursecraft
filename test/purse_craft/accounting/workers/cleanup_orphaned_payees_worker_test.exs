defmodule PurseCraft.Accounting.Workers.CleanupOrphanedPayeesWorkerTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Accounting.Commands.Payees.CleanupOrphanedPayees
  alias PurseCraft.Accounting.Workers.CleanupOrphanedPayeesWorker
  alias PurseCraft.Core.Commands.Workspaces.FetchWorkspace
  alias PurseCraft.CoreFactory

  setup :verify_on_exit!

  setup do
    copy(CleanupOrphanedPayees)
    copy(FetchWorkspace)
    :ok
  end

  describe "perform/1" do
    test "successfully processes payee cleanup job" do
      workspace = CoreFactory.build(:workspace, id: 123)

      expect(FetchWorkspace, :call, fn 123 ->
        {:ok, workspace}
      end)

      expect(CleanupOrphanedPayees, :call, fn ^workspace ->
        {:ok, 3}
      end)

      job = %Oban.Job{
        args: %{
          "workspace_id" => 123
        }
      }

      assert CleanupOrphanedPayeesWorker.perform(job) == :ok
      verify!()
    end

    test "returns error when FetchWorkspace fails" do
      expect(FetchWorkspace, :call, fn 456 ->
        {:error, :not_found}
      end)

      job = %Oban.Job{
        args: %{
          "workspace_id" => 456
        }
      }

      assert CleanupOrphanedPayeesWorker.perform(job) == {:error, :not_found}
      verify!()
    end

    test "returns error when CleanupOrphanedPayees fails" do
      workspace = CoreFactory.build(:workspace, id: 789)

      expect(FetchWorkspace, :call, fn 789 ->
        {:ok, workspace}
      end)

      expect(CleanupOrphanedPayees, :call, fn ^workspace ->
        {:error, :database_error}
      end)

      job = %Oban.Job{
        args: %{
          "workspace_id" => 789
        }
      }

      assert CleanupOrphanedPayeesWorker.perform(job) == {:error, :database_error}
      verify!()
    end
  end
end
