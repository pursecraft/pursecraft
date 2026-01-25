defmodule PurseCraft.Identity.Events.UserPasswordUpdatedTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Events.UserPasswordUpdated

  test "creates struct with required fields" do
    event = %UserPasswordUpdated{
      user_uuid: "uuid"
    }

    assert event.user_uuid == "uuid"
  end
end
