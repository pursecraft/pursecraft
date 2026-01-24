defmodule PurseCraft.Identity.Events.UserEmailChangedTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Events.UserEmailChanged

  test "creates struct with required fields" do
    event = %UserEmailChanged{
      user_uuid: "uuid",
      old_email: "old@example.com",
      new_email: "new@example.com",
      timestamp: DateTime.utc_now()
    }

    assert event.user_uuid == "uuid"
    assert event.old_email == "old@example.com"
    assert event.new_email == "new@example.com"
    assert %DateTime{} = event.timestamp
  end
end
