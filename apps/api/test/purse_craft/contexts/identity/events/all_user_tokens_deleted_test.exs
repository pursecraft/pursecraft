defmodule PurseCraft.Identity.Events.AllUserTokensDeletedTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Events.AllUserTokensDeleted

  test "creates struct with required fields" do
    event = %AllUserTokensDeleted{
      user_uuid: "uuid",
      token_type: :session,
      except_token: "current-token",
      timestamp: DateTime.utc_now()
    }

    assert event.user_uuid == "uuid"
    assert event.token_type == :session
    assert event.except_token == "current-token"
    assert %DateTime{} = event.timestamp
  end

  test "creates struct with optional fields nil" do
    event = %AllUserTokensDeleted{
      user_uuid: "uuid",
      timestamp: DateTime.utc_now()
    }

    assert event.user_uuid == "uuid"
    assert event.token_type == nil
    assert event.except_token == nil
    assert %DateTime{} = event.timestamp
  end
end
