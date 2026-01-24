defmodule PurseCraft.Identity.Commands.RecordAuthenticationAttemptTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Commands.RecordAuthenticationAttempt

  test "creates struct with required fields" do
    command = %RecordAuthenticationAttempt{
      user_uuid: "uuid",
      success: true,
      metadata: %{ip: "127.0.0.1"}
    }

    assert command.user_uuid == "uuid"
    assert command.success == true
    assert command.metadata == %{ip: "127.0.0.1"}
  end
end
