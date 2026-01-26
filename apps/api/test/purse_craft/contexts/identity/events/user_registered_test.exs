defmodule PurseCraft.Identity.Events.UserRegisteredTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Events.UserRegistered

  test "creates struct with required fields" do
    user_uuid = Commanded.UUID.uuid4()

    event = %UserRegistered{
      user_uuid: user_uuid,
      email: "test@example.com",
      hashed_password: "hash",
      confirmed_at: nil
    }

    assert event.user_uuid == user_uuid
    assert event.email == "test@example.com"
    assert event.hashed_password == "hash"
    assert event.confirmed_at == nil
  end
end
