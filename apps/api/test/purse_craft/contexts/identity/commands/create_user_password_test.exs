defmodule PurseCraft.Identity.Commands.CreateUserPasswordTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Commands.CreateUserPassword

  test "creates struct with required fields" do
    user_uuid = Commanded.UUID.uuid4()

    command = %CreateUserPassword{
      user_uuid: user_uuid,
      password: "password123",
      password_confirmation: "password123"
    }

    assert command.user_uuid == user_uuid
    assert command.password == "password123"
    assert command.password_confirmation == "password123"
  end
end
