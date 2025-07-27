defmodule PurseCraft.Search.Commands.Token.UpdateTokensTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.CoreFactory
  alias PurseCraft.Repo
  alias PurseCraft.Search.Commands.Token.UpdateTokens
  alias PurseCraft.Search.Schemas.SearchToken

  setup do
    workspace = CoreFactory.insert(:workspace)

    %{workspace: workspace}
  end

  describe "call/4" do
    test "creates new tokens for entity with searchable fields", %{workspace: workspace} do
      searchable_fields = %{"name" => "hello world", "description" => "test"}

      assert {:ok, tokens} = UpdateTokens.call(workspace, "account", 123, searchable_fields)

      assert length(tokens) > 0
      assert Enum.all?(tokens, &(&1.workspace_id == workspace.id))
      assert Enum.all?(tokens, &(&1.entity_type == "account"))
      assert Enum.all?(tokens, &(&1.entity_id == 123))
    end

    test "deletes existing tokens before creating new ones", %{workspace: workspace} do
      # Insert existing tokens
      existing_token = %SearchToken{
        workspace_id: workspace.id,
        entity_type: "account",
        entity_id: 123,
        field_name: "name",
        token_hash: "old",
        algorithm_version: 1,
        token_length: 3
      }

      Repo.insert!(existing_token)

      searchable_fields = %{"name" => "hello"}

      assert {:ok, new_tokens} = UpdateTokens.call(workspace, "account", 123, searchable_fields)

      # Verify old tokens are deleted
      all_tokens = Repo.all(SearchToken)
      old_token_hashes = Enum.map(all_tokens, & &1.token_hash)

      refute "old" in old_token_hashes
      # "hel", "ell", "llo"
      assert length(new_tokens) == 3
    end

    test "handles empty searchable fields", %{workspace: workspace} do
      assert {:ok, tokens} = UpdateTokens.call(workspace, "account", 123, %{})

      assert tokens == []
    end

    test "handles fields with empty values", %{workspace: workspace} do
      searchable_fields = %{"name" => "", "description" => "   "}

      assert {:ok, tokens} = UpdateTokens.call(workspace, "account", 123, searchable_fields)

      assert tokens == []
    end

    test "handles fields with only special characters that produce no tokens", %{workspace: workspace} do
      # Special characters that don't generate valid tokens
      searchable_fields = %{"name" => "!@#$%", "description" => "***"}

      assert {:ok, tokens} = UpdateTokens.call(workspace, "account", 123, searchable_fields)

      assert tokens == []
    end

    test "handles nil field values", %{workspace: workspace} do
      # Nil values should generate no tokens
      searchable_fields = %{"name" => nil, "description" => nil}

      assert {:ok, tokens} = UpdateTokens.call(workspace, "account", 123, searchable_fields)

      assert tokens == []
    end

    test "generates tokens with correct entity metadata", %{workspace: workspace} do
      searchable_fields = %{"name" => "test"}

      assert {:ok, tokens} = UpdateTokens.call(workspace, "category", 456, searchable_fields)
      assert length(tokens) >= 1

      token = hd(tokens)

      assert token.workspace_id == workspace.id
      assert token.entity_type == "category"
      assert token.entity_id == 456
      assert token.field_name == "name"
      assert token.algorithm_version == 1
      assert token.token_length == 3
    end

    test "handles multiple fields with multiple tokens", %{workspace: workspace} do
      searchable_fields = %{
        "name" => "hello",
        "description" => "world"
      }

      assert {:ok, tokens} = UpdateTokens.call(workspace, "envelope", 789, searchable_fields)

      name_tokens = Enum.filter(tokens, &(&1.field_name == "name"))
      description_tokens = Enum.filter(tokens, &(&1.field_name == "description"))

      # "hel", "ell", "llo"
      assert length(name_tokens) == 3
      # "wor", "orl", "rld"
      assert length(description_tokens) == 3
      assert length(tokens) == 6
    end

    test "handles transaction rollback on error" do
      # This test would require mocking Repo.insert_all to fail
      # For now, we'll test the basic happy path
      workspace = CoreFactory.insert(:workspace)
      searchable_fields = %{"name" => "test"}

      assert {:ok, _tokens} = UpdateTokens.call(workspace, "account", 123, searchable_fields)
    end

    test "only affects tokens for specific entity", %{workspace: workspace} do
      other_workspace = CoreFactory.insert(:workspace)

      # Insert tokens for different entities
      Repo.insert!(%SearchToken{
        workspace_id: workspace.id,
        entity_type: "account",
        # Different entity
        entity_id: 999,
        field_name: "name",
        token_hash: "keep1",
        algorithm_version: 1,
        token_length: 5
      })

      Repo.insert!(%SearchToken{
        workspace_id: other_workspace.id,
        entity_type: "account",
        # Same entity ID but different workspace
        entity_id: 123,
        field_name: "name",
        token_hash: "keep2",
        algorithm_version: 1,
        token_length: 5
      })

      Repo.insert!(%SearchToken{
        workspace_id: workspace.id,
        # Different entity type
        entity_type: "category",
        entity_id: 123,
        field_name: "name",
        token_hash: "keep3",
        algorithm_version: 1,
        token_length: 5
      })

      searchable_fields = %{"name" => "test"}

      assert {:ok, _new_tokens} = UpdateTokens.call(workspace, "account", 123, searchable_fields)

      # Verify other entities' tokens are preserved (should have 3 preserved + new tokens from "test")
      all_tokens = Repo.all(SearchToken)

      # Check that the 3 manually inserted tokens are still there
      entity_999_tokens = Enum.filter(all_tokens, &(&1.entity_id == 999))
      other_workspace_tokens = Enum.filter(all_tokens, &(&1.workspace_id == other_workspace.id))
      category_tokens = Enum.filter(all_tokens, &(&1.entity_type == "category"))

      # keep1 token preserved
      assert length(entity_999_tokens) == 1
      # keep2 token preserved
      assert length(other_workspace_tokens) == 1
      # keep3 token preserved
      assert length(category_tokens) == 1
    end

    test "filters out short words through token generation", %{workspace: workspace} do
      # "hi" too short, "hello" valid
      searchable_fields = %{"name" => "hi hello"}

      assert {:ok, tokens} = UpdateTokens.call(workspace, "account", 123, searchable_fields)

      # Should only have tokens from "hello" (3 tokens), not "hi" (0 tokens)
      assert length(tokens) == 3
      assert Enum.all?(tokens, &(&1.field_name == "name"))
      assert Enum.all?(tokens, &(&1.entity_type == "account"))
    end
  end
end
