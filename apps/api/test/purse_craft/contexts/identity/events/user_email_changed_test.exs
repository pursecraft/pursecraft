defmodule PurseCraft.Identity.Events.UserEmailChangedTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Events.UserEmailChanged

  test "creates struct with required fields" do
    user_uuid = Commanded.UUID.uuid4()

    event = %UserEmailChanged{
      user_uuid: user_uuid,
      old_email: "old@example.com",
      new_email: "new@example.com"
    }

    assert event.user_uuid == user_uuid
    assert event.old_email == "old@example.com"
    assert event.new_email == "new@example.com"
  end
end
