defmodule PurseCraft.Identity.Commands.UpdateUserPasswordTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Commands.UpdateUserPassword

  test "creates struct with required fields" do
    user_uuid = Commanded.UUID.uuid4()

    command = %UpdateUserPassword{
      user_uuid: user_uuid,
      current_password: "old",
      new_password: "new",
      password_confirmation: "new"
    }

    assert command.user_uuid == user_uuid
    assert command.current_password == "old"
    assert command.new_password == "new"
    assert command.password_confirmation == "new"
  end
end
