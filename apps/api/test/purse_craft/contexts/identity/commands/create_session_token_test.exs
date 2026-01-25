defmodule PurseCraft.Identity.Commands.CreateSessionTokenTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Commands.CreateSessionToken

  test "creates struct with required fields" do
    user_uuid = Commanded.UUID.uuid4()

    command = %CreateSessionToken{
      user_uuid: user_uuid,
      user_agent: "Mozilla",
      ip_address: "127.0.0.1"
    }

    assert command.user_uuid == user_uuid
    assert command.user_agent == "Mozilla"
    assert command.ip_address == "127.0.0.1"
  end
end
