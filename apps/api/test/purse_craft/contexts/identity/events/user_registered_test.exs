defmodule PurseCraft.Identity.Events.UserRegisteredTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Events.UserRegistered

  test "creates struct with required fields" do
    event = %UserRegistered{
      user_uuid: "uuid",
      email: "test@example.com",
      hashed_password: "hash",
      confirmed_at: nil
    }

    assert event.user_uuid == "uuid"
    assert event.email == "test@example.com"
    assert event.hashed_password == "hash"
    assert event.confirmed_at == nil
  end
end
