defmodule PurseCraft.Identity.Commands.ConfirmUserEmailTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Commands.ConfirmUserEmail

  test "creates struct with user_uuid" do
    user_uuid = Commanded.UUID.uuid4()

    command = %ConfirmUserEmail{user_uuid: user_uuid}

    assert command.user_uuid == user_uuid
  end
end
