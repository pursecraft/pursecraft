defmodule PurseCraft.Identity.Events.TokenDeletedTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Events.TokenDeleted

  test "creates struct with required fields" do
    event = %TokenDeleted{
      token: "token123",
      timestamp: DateTime.utc_now()
    }

    assert event.token == "token123"
    assert %DateTime{} = event.timestamp
  end
end
