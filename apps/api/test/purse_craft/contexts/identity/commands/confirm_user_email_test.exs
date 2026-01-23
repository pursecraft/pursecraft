defmodule PurseCraft.Identity.Commands.ConfirmUserEmailTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Commands.ConfirmUserEmail

  test "creates struct with user_uuid" do
    command = %ConfirmUserEmail{user_uuid: "uuid"}

    assert command.user_uuid == "uuid"
  end
end
