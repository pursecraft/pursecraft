defmodule PurseCraft.Identity.Commands.ConsumeTokenTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Commands.ConsumeToken

  test "creates struct with token" do
    command = %ConsumeToken{token: "token123"}

    assert command.token == "token123"
  end
end
