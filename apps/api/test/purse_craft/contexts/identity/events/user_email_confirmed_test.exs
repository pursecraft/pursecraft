defmodule PurseCraft.Identity.Events.UserEmailConfirmedTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Events.UserEmailConfirmed

  test "creates struct with required fields" do
    event = %UserEmailConfirmed{
      user_uuid: "uuid",
      email: "test@example.com",
      timestamp: DateTime.utc_now()
    }

    assert event.user_uuid == "uuid"
    assert event.email == "test@example.com"
    assert %DateTime{} = event.timestamp
  end
end
