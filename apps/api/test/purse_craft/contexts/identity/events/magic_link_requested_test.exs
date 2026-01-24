defmodule PurseCraft.Identity.Events.MagicLinkRequestedTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Events.MagicLinkRequested

  test "creates struct with required fields" do
    event = %MagicLinkRequested{
      token: "token123",
      user_uuid: "uuid",
      email: "test@example.com",
      expires_at: DateTime.utc_now(),
      timestamp: DateTime.utc_now()
    }

    assert event.token == "token123"
    assert event.user_uuid == "uuid"
    assert event.email == "test@example.com"
    assert %DateTime{} = event.expires_at
    assert %DateTime{} = event.timestamp
  end
end
