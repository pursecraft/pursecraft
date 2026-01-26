defmodule PurseCraft.Identity.Events.UserEmailChangeRequestedTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Events.UserEmailChangeRequested

  test "creates struct with required fields" do
    user_uuid = Commanded.UUID.uuid4()

    event = %UserEmailChangeRequested{
      user_uuid: user_uuid,
      current_email: "old@example.com",
      new_email: "new@example.com"
    }

    assert event.user_uuid == user_uuid
    assert event.current_email == "old@example.com"
    assert event.new_email == "new@example.com"
  end
end
