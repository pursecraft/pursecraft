defmodule PurseCraft.Identity.Events.SessionTokenCreatedTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Events.SessionTokenCreated

  test "creates struct with required fields" do
    user_uuid = Commanded.UUID.uuid4()

    event = %SessionTokenCreated{
      token: "token123",
      user_uuid: user_uuid,
      user_agent: "Mozilla",
      ip_address: "127.0.0.1",
      expires_at: DateTime.utc_now()
    }

    assert event.token == "token123"
    assert event.user_uuid == user_uuid
    assert event.user_agent == "Mozilla"
    assert event.ip_address == "127.0.0.1"
    assert %DateTime{} = event.expires_at
  end
end
