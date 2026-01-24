defmodule PurseCraft.Identity.Events.TokenConsumedTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Events.TokenConsumed

  test "creates struct with required fields" do
    consumed_at = DateTime.utc_now()

    event = %TokenConsumed{
      token: "token123",
      consumed_at: consumed_at,
      timestamp: DateTime.utc_now()
    }

    assert event.token == "token123"
    assert event.consumed_at == consumed_at
    assert %DateTime{} = event.timestamp
  end
end
