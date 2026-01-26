defmodule PurseCraft.Identity.Events.TokenDeletedTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Events.TokenDeleted

  test "creates struct with required fields" do
    event = %TokenDeleted{
      token: "token123"
    }

    assert event.token == "token123"
  end
end
