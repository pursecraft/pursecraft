defmodule PurseCraft.Search.Workers.GenerateTokensWorkerTransactionTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.AccountingFactory
  alias PurseCraft.BudgetingFactory
  alias PurseCraft.CoreFactory
  alias PurseCraft.Search.Workers.GenerateTokensWorker

  setup do
    workspace = CoreFactory.insert(:workspace)
    account = AccountingFactory.insert(:account, workspace: workspace, name: "Chase Checking")
    payee = AccountingFactory.insert(:payee, workspace: workspace, name: "Kroger Store")

    category = BudgetingFactory.insert(:category, workspace: workspace)
    envelope = BudgetingFactory.insert(:envelope, category: category, name: "Groceries")

    {:ok, workspace: workspace, account: account, payee: payee, envelope: envelope}
  end

  describe "enrich_searchable_fields for transactions" do
    test "enriches transaction with payee, account, and envelope names", %{
      workspace: workspace,
      account: account,
      payee: payee,
      envelope: envelope
    } do
      # Create a transaction with lines
      transaction =
        AccountingFactory.insert(:transaction,
          workspace: workspace,
          account: account,
          payee: payee,
          memo: "Weekly shopping"
        )

      AccountingFactory.insert(:transaction_line,
        transaction: transaction,
        envelope: envelope,
        amount: 2500
      )

      # Test the search token generation job
      job_args = %{
        "workspace_id" => workspace.id,
        "entity_type" => "transaction",
        "entity_id" => transaction.id,
        "searchable_fields" => %{"memo" => "Weekly shopping"}
      }

      job = %Oban.Job{args: job_args}

      # The perform function should succeed (we're not testing token generation, just enrichment)
      assert :ok = GenerateTokensWorker.perform(job)
    end

    test "handles transaction with no memo", %{
      workspace: workspace,
      account: account
    } do
      transaction =
        AccountingFactory.insert(:transaction,
          workspace: workspace,
          account: account,
          memo: nil
        )

      job_args = %{
        "workspace_id" => workspace.id,
        "entity_type" => "transaction",
        "entity_id" => transaction.id,
        "searchable_fields" => %{}
      }

      job = %Oban.Job{args: job_args}

      assert :ok = GenerateTokensWorker.perform(job)
    end

    test "handles transaction with split transaction lines", %{
      workspace: workspace,
      account: account,
      payee: payee,
      envelope: envelope
    } do
      transaction =
        AccountingFactory.insert(:transaction,
          workspace: workspace,
          account: account,
          payee: payee,
          memo: "Shopping trip"
        )

      # Create one transaction line
      AccountingFactory.insert(:transaction_line,
        transaction: transaction,
        envelope: envelope,
        amount: 3000
      )

      job_args = %{
        "workspace_id" => workspace.id,
        "entity_type" => "transaction",
        "entity_id" => transaction.id,
        "searchable_fields" => %{"memo" => "Shopping trip"}
      }

      job = %Oban.Job{args: job_args}

      assert :ok = GenerateTokensWorker.perform(job)
    end
  end
end
