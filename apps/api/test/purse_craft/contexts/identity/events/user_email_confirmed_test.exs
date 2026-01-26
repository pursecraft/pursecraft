defmodule PurseCraft.Identity.Events.UserEmailConfirmedTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Events.UserEmailConfirmed

  test "creates struct with required fields" do
    now = DateTime.utc_now()
    user_uuid = Commanded.UUID.uuid4()

    event = %UserEmailConfirmed{
      user_uuid: user_uuid,
      email: "test@example.com",
      confirmed_at: now
    }

    assert event.user_uuid == user_uuid
    assert event.email == "test@example.com"
    assert %DateTime{} = event.confirmed_at
  end
end
