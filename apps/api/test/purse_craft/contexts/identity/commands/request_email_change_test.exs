defmodule PurseCraft.Identity.Commands.RequestEmailChangeTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Commands.RequestEmailChange

  test "creates struct with required fields" do
    command = %RequestEmailChange{user_uuid: "uuid", new_email: "new@example.com"}

    assert command.user_uuid == "uuid"
    assert command.new_email == "new@example.com"
  end
end
