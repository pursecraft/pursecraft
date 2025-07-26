defmodule PurseCraft.Search.Workers.GenerateTokensWorkerTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Core.Commands.Workspaces.FetchWorkspace
  alias PurseCraft.CoreFactory
  alias PurseCraft.Search.Commands.Token.UpdateTokens
  alias PurseCraft.Search.Workers.GenerateTokensWorker

  describe "perform/1" do
    test "successfully processes token generation job" do
      workspace = CoreFactory.build(:workspace)

      expect(FetchWorkspace, :call, fn 123 ->
        {:ok, workspace}
      end)

      expect(UpdateTokens, :call, fn ^workspace, "account", 456, %{"name" => "My Account"} ->
        {:ok, []}
      end)

      job = %Oban.Job{
        args: %{
          "workspace_id" => 123,
          "entity_type" => "account",
          "entity_id" => 456,
          "searchable_fields" => %{"name" => "My Account"}
        }
      }

      assert GenerateTokensWorker.perform(job) == :ok
      verify!()
    end

    test "returns error when workspace fetch fails" do
      expect(FetchWorkspace, :call, fn 999 ->
        {:error, :not_found}
      end)

      job = %Oban.Job{
        args: %{
          "workspace_id" => 999,
          "entity_type" => "account",
          "entity_id" => 456,
          "searchable_fields" => %{"name" => "My Account"}
        }
      }

      assert GenerateTokensWorker.perform(job) == {:error, :not_found}
      verify!()
    end

    test "returns error when UpdateTokens fails" do
      workspace = CoreFactory.build(:workspace)

      expect(FetchWorkspace, :call, fn 123 ->
        {:ok, workspace}
      end)

      expect(UpdateTokens, :call, fn ^workspace, "account", 456, %{"name" => "My Account"} ->
        {:error, :validation_failed}
      end)

      job = %Oban.Job{
        args: %{
          "workspace_id" => 123,
          "entity_type" => "account",
          "entity_id" => 456,
          "searchable_fields" => %{"name" => "My Account"}
        }
      }

      assert GenerateTokensWorker.perform(job) == {:error, :validation_failed}
      verify!()
    end
  end
end
