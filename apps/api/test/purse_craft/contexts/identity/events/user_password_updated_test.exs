defmodule PurseCraft.Identity.Events.UserPasswordUpdatedTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Events.UserPasswordUpdated

  test "creates struct with required fields" do
    user_uuid = Commanded.UUID.uuid4()

    event = %UserPasswordUpdated{
      user_uuid: user_uuid
    }

    assert event.user_uuid == user_uuid
  end
end
