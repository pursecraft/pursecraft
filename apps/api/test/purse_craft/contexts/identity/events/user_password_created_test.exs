defmodule PurseCraft.Identity.Events.UserPasswordCreatedTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Events.UserPasswordCreated

  test "creates struct with required fields" do
    user_uuid = Commanded.UUID.uuid4()

    event = %UserPasswordCreated{
      user_uuid: user_uuid,
      hashed_password: "hash"
    }

    assert event.user_uuid == user_uuid
    assert event.hashed_password == "hash"
  end
end
