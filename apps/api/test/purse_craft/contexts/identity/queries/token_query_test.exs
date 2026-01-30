defmodule PurseCraft.Identity.Queries.TokenQueryTest do
  use PurseCraft.DataCase, async: true

  import Ecto.Query

  alias PurseCraft.Identity.Queries.TokenQuery
  alias PurseCraft.Identity.ReadModels.Token

  describe "by_token/1" do
    test "creates query from token" do
      token = :crypto.strong_rand_bytes(32)
      query = TokenQuery.by_token(token)
      assert %Ecto.Query{} = query
    end

    test "can be composed with other queries" do
      token = :crypto.strong_rand_bytes(32)

      query =
        Token
        |> TokenQuery.by_token(token)
        |> TokenQuery.by_context("session")

      assert %Ecto.Query{} = query
    end
  end

  describe "by_token/2" do
    test "works with queryable" do
      base_query = from(t in Token, select: t.id)
      token = :crypto.strong_rand_bytes(32)
      composed = TokenQuery.by_token(base_query, token)
      assert %Ecto.Query{} = composed
    end
  end

  describe "by_context/1" do
    test "creates query from context" do
      query = TokenQuery.by_context("session")
      assert %Ecto.Query{} = query
    end

    test "can be composed with other queries" do
      token = :crypto.strong_rand_bytes(32)

      query =
        Token
        |> TokenQuery.by_context("session")
        |> TokenQuery.by_token(token)

      assert %Ecto.Query{} = query
    end
  end

  describe "by_context/2" do
    test "works with queryable" do
      base_query = from(t in Token, select: t.id)
      composed = TokenQuery.by_context(base_query, "session")
      assert %Ecto.Query{} = composed
    end
  end

  describe "by_user_uuid/1" do
    test "creates query from user_uuid" do
      query = TokenQuery.by_user_uuid("user-uuid")
      assert %Ecto.Query{} = query
    end

    test "can be composed with other queries" do
      query =
        Token
        |> TokenQuery.by_user_uuid("user-uuid")
        |> TokenQuery.by_context("session")

      assert %Ecto.Query{} = query
    end
  end

  describe "by_user_uuid/2" do
    test "works with queryable" do
      base_query = from(t in Token, select: t.id)
      composed = TokenQuery.by_user_uuid(base_query, "user-uuid")
      assert %Ecto.Query{} = composed
    end
  end

  describe "not_expired/0" do
    test "creates query for non-expired tokens" do
      query = TokenQuery.not_expired()
      assert %Ecto.Query{} = query
    end

    test "can be composed with other queries" do
      query =
        Token
        |> TokenQuery.by_context("session")
        |> TokenQuery.not_expired()

      assert %Ecto.Query{} = query
    end
  end

  describe "not_expired/1" do
    test "works with queryable" do
      base_query = from(t in Token, select: t.id)
      composed = TokenQuery.not_expired(base_query)
      assert %Ecto.Query{} = composed
    end
  end

  describe "not_consumed/0" do
    test "creates query for non-consumed tokens" do
      query = TokenQuery.not_consumed()
      assert %Ecto.Query{} = query
    end

    test "can be composed with other queries" do
      query =
        Token
        |> TokenQuery.by_context("magic_link")
        |> TokenQuery.not_consumed()

      assert %Ecto.Query{} = query
    end
  end

  describe "not_consumed/1" do
    test "works with queryable" do
      base_query = from(t in Token, select: t.id)
      composed = TokenQuery.not_consumed(base_query)
      assert %Ecto.Query{} = composed
    end
  end

  describe "active/0" do
    test "creates query for active tokens" do
      query = TokenQuery.active()
      assert %Ecto.Query{} = query
    end

    test "can be composed with other queries" do
      query =
        Token
        |> TokenQuery.by_user_uuid("user-uuid")
        |> TokenQuery.active()

      assert %Ecto.Query{} = query
    end
  end

  describe "active/1" do
    test "works with queryable" do
      base_query = from(t in Token, select: t.id)
      composed = TokenQuery.active(base_query)
      assert %Ecto.Query{} = composed
    end

    test "composes not_expired and not_consumed" do
      base_query = from(t in Token, select: t.id)

      composed =
        base_query
        |> TokenQuery.active()
        |> TokenQuery.by_token("some-token")

      assert %Ecto.Query{} = composed
    end
  end
end
