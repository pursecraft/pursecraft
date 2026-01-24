defmodule PurseCraft.Identity.Events.UserPasswordCreatedTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Events.UserPasswordCreated

  test "creates struct with required fields" do
    event = %UserPasswordCreated{
      user_uuid: "uuid",
      hashed_password: "hash",
      timestamp: DateTime.utc_now()
    }

    assert event.user_uuid == "uuid"
    assert event.hashed_password == "hash"
    assert %DateTime{} = event.timestamp
  end
end
