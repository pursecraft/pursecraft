defmodule PurseCraft.Identity.Events.AllUserTokensDeletedTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Events.AllUserTokensDeleted

  test "creates struct with required fields" do
    user_uuid = Commanded.UUID.uuid4()

    event = %AllUserTokensDeleted{
      user_uuid: user_uuid,
      token_type: :session,
      except_token: "current-token"
    }

    assert event.user_uuid == user_uuid
    assert event.token_type == :session
    assert event.except_token == "current-token"
  end

  test "creates struct with optional fields nil" do
    user_uuid = Commanded.UUID.uuid4()

    event = %AllUserTokensDeleted{
      user_uuid: user_uuid
    }

    assert event.user_uuid == user_uuid
    assert event.token_type == nil
    assert event.except_token == nil
  end
end
