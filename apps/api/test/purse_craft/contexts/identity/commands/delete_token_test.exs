defmodule PurseCraft.Identity.Commands.DeleteTokenTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Commands.DeleteToken

  test "creates struct with token" do
    command = %DeleteToken{token: "token123"}

    assert command.token == "token123"
  end
end
