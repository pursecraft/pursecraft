defmodule PurseCraft.Identity.Commands.RequestEmailChangeTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Commands.RequestEmailChange

  test "creates struct with required fields" do
    user_uuid = Commanded.UUID.uuid4()

    command = %RequestEmailChange{user_uuid: user_uuid, new_email: "new@example.com"}

    assert command.user_uuid == user_uuid
    assert command.new_email == "new@example.com"
  end
end
