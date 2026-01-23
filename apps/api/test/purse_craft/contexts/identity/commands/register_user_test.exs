defmodule PurseCraft.Identity.Commands.RegisterUserTest do
  use PurseCraft.DataCase
  alias PurseCraft.Identity.Commands.RegisterUser

  test "creates struct with required fields" do
    command = %RegisterUser{user_uuid: "uuid", email: "test@example.com"}

    assert command.user_uuid == "uuid"
    assert command.email == "test@example.com"
    assert command.password == nil
  end

  test "creates struct with optional password" do
    command = %RegisterUser{user_uuid: "uuid", email: "test@example.com", password: "pass"}

    assert command.password == "pass"
  end
end
