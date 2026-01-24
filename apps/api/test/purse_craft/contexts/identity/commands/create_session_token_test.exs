defmodule PurseCraft.Identity.Commands.CreateSessionTokenTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Commands.CreateSessionToken

  test "creates struct with required fields" do
    command = %CreateSessionToken{
      user_uuid: "uuid",
      user_agent: "Mozilla",
      ip_address: "127.0.0.1"
    }

    assert command.user_uuid == "uuid"
    assert command.user_agent == "Mozilla"
    assert command.ip_address == "127.0.0.1"
  end
end
