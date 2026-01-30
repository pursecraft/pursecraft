defmodule PurseCraft.Identity.Queries.UserQueryTest do
  use PurseCraft.DataCase, async: true

  import Ecto.Query

  alias PurseCraft.Identity.Queries.UserQuery
  alias PurseCraft.Identity.ReadModels.User

  describe "by_id/1" do
    test "creates query from id" do
      query = UserQuery.by_id("some-uuid")
      assert %Ecto.Query{} = query
    end

    test "can be composed with other queries" do
      base_query = from(u in User, select: u.id)

      query =
        base_query
        |> UserQuery.by_id("some-uuid")
        |> UserQuery.by_email("test@example.com")

      assert %Ecto.Query{} = query
    end
  end

  describe "by_id/2" do
    test "works with queryable" do
      base_query = from(u in User, select: u.id)
      composed = UserQuery.by_id(base_query, "some-uuid")
      assert %Ecto.Query{} = composed
    end
  end

  describe "by_email/1" do
    test "creates query from email" do
      query = UserQuery.by_email("test@example.com")
      assert %Ecto.Query{} = query
    end

    test "can be composed with other queries" do
      base_query = from(u in User, select: u.id)

      query =
        base_query
        |> UserQuery.by_email("test@example.com")

      assert %Ecto.Query{} = query
    end
  end

  describe "by_email/2" do
    test "works with queryable" do
      base_query = from(u in User, select: u.id)
      composed = UserQuery.by_email(base_query, "test@example.com")
      assert %Ecto.Query{} = composed
    end
  end
end
