defmodule PurseCraft.Search.Workers.DeleteTokensWorkerTest do
  use PurseCraft.DataCase, async: true

  import Mimic

  alias PurseCraft.Search.Commands.Token.DeleteTokens
  alias PurseCraft.Search.Workers.DeleteTokensWorker

  describe "perform/1" do
    test "successfully processes token deletion job" do
      expect(DeleteTokens, :call, fn "account", 123 ->
        {:ok, 5}
      end)

      job = %Oban.Job{
        args: %{
          "entity_type" => "account",
          "entity_id" => 123
        }
      }

      assert DeleteTokensWorker.perform(job) == :ok
      verify!()
    end

    test "returns error when DeleteTokens fails" do
      expect(DeleteTokens, :call, fn "category", 456 ->
        {:error, :database_error}
      end)

      job = %Oban.Job{
        args: %{
          "entity_type" => "category",
          "entity_id" => 456
        }
      }

      assert DeleteTokensWorker.perform(job) == {:error, :database_error}
      verify!()
    end
  end
end
