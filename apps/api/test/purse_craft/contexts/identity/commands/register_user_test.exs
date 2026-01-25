defmodule PurseCraft.Identity.Commands.RegisterUserTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Commands.RegisterUser

  test "creates struct with required fields" do
    user_uuid = Commanded.UUID.uuid4()

    command = %RegisterUser{user_uuid: user_uuid, email: "test@example.com"}

    assert command.user_uuid == user_uuid
    assert command.email == "test@example.com"
    assert command.password == nil
  end

  test "creates struct with optional password" do
    user_uuid = Commanded.UUID.uuid4()

    command = %RegisterUser{user_uuid: user_uuid, email: "test@example.com", password: "pass"}

    assert command.password == "pass"
  end
end
