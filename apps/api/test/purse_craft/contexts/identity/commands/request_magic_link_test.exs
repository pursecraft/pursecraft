defmodule PurseCraft.Identity.Commands.RequestMagicLinkTest do
  use PurseCraft.DataCase
  alias PurseCraft.Identity.Commands.RequestMagicLink

  test "creates struct with required fields" do
    command = %RequestMagicLink{email: "test@example.com", metadata: %{ip: "127.0.0.1"}}

    assert command.email == "test@example.com"
    assert command.metadata == %{ip: "127.0.0.1"}
  end

  test "creates struct with nil metadata" do
    command = %RequestMagicLink{email: "test@example.com"}

    assert command.email == "test@example.com"
    assert command.metadata == nil
  end
end
