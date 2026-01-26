defmodule PurseCraft.Identity.Aggregates.TokenTest do
  use PurseCraft.DataCase, async: true

  alias PurseCraft.Identity.Aggregates.Token
  alias PurseCraft.Identity.Commands.ConsumeToken
  alias PurseCraft.Identity.Commands.CreateSessionToken
  alias PurseCraft.Identity.Commands.DeleteToken
  alias PurseCraft.Identity.Commands.RequestMagicLink
  alias PurseCraft.Identity.Events.MagicLinkRequested
  alias PurseCraft.Identity.Events.SessionTokenCreated
  alias PurseCraft.Identity.Events.TokenConsumed
  alias PurseCraft.Identity.Events.TokenDeleted

  @now DateTime.utc_now(:second)

  describe "execute/2 - RequestMagicLink" do
    test "creates MagicLinkRequested event for new token" do
      user_uuid = Commanded.UUID.uuid4()

      command = %RequestMagicLink{
        email: "test@example.com",
        user_uuid: user_uuid
      }

      assert {:ok, %MagicLinkRequested{email: "test@example.com", user_uuid: ^user_uuid}} =
               Token.execute(%Token{token: nil}, command)
    end

    test "generates token with 15 minute expiry" do
      command = %RequestMagicLink{
        email: "test@example.com"
      }

      assert {:ok, %MagicLinkRequested{expires_at: expires_at}} =
               Token.execute(%Token{token: nil}, command)

      expected_expiry = DateTime.add(@now, 60 * 15, :second)

      assert DateTime.diff(expires_at, expected_expiry, :second) <= 1
    end
  end

  describe "execute/2 - CreateSessionToken" do
    test "creates SessionTokenCreated event for new token" do
      user_uuid = Commanded.UUID.uuid4()

      command = %CreateSessionToken{
        user_uuid: user_uuid,
        user_agent: "Mozilla/5.0",
        ip_address: "127.0.0.1"
      }

      assert {:ok, %SessionTokenCreated{user_uuid: ^user_uuid}} =
               Token.execute(%Token{token: nil}, command)
    end

    test "generates session token with 7 day expiry" do
      user_uuid = Commanded.UUID.uuid4()

      command = %CreateSessionToken{
        user_uuid: user_uuid
      }

      assert {:ok, %SessionTokenCreated{expires_at: expires_at}} =
               Token.execute(%Token{token: nil}, command)

      expected_expiry = DateTime.add(@now, 60 * 60 * 24 * 7, :second)

      assert DateTime.diff(expires_at, expected_expiry, :second) <= 1
    end

    test "supports custom token type" do
      user_uuid = Commanded.UUID.uuid4()

      command = %CreateSessionToken{
        user_uuid: user_uuid,
        token_type: :email_confirmation
      }

      assert {:ok, %SessionTokenCreated{expires_at: expires_at}} =
               Token.execute(%Token{token: nil}, command)

      # email_confirmation should have 3 day expiry
      expected_expiry = DateTime.add(@now, 60 * 60 * 24 * 3, :second)

      assert DateTime.diff(expires_at, expected_expiry, :second) <= 1
    end
  end

  describe "execute/2 - ConsumeToken" do
    test "creates TokenConsumed event for valid consumable token" do
      token_value = Commanded.UUID.uuid4()
      expires_at = DateTime.add(@now, 3600, :second)

      token = %Token{
        token: token_value,
        type: :magic_link,
        expires_at: expires_at,
        consumed_at: nil
      }

      command = %ConsumeToken{token: token_value}

      assert {:ok, %TokenConsumed{token: ^token_value}} = Token.execute(token, command)
    end

    test "returns error when token is already consumed" do
      token_value = Commanded.UUID.uuid4()
      expires_at = DateTime.add(@now, 3600, :second)

      token = %Token{
        token: token_value,
        type: :magic_link,
        expires_at: expires_at,
        consumed_at: DateTime.utc_now(:second)
      }

      command = %ConsumeToken{token: token_value}

      assert {:error, :already_consumed} = Token.execute(token, command)
    end

    test "returns error when token is expired" do
      token_value = Commanded.UUID.uuid4()
      expires_at = DateTime.add(@now, -3600, :second)

      token = %Token{
        token: token_value,
        type: :magic_link,
        expires_at: expires_at,
        consumed_at: nil
      }

      command = %ConsumeToken{token: token_value}

      assert {:error, :expired} = Token.execute(token, command)
    end

    test "returns error when token type is not consumable" do
      token_value = Commanded.UUID.uuid4()
      expires_at = DateTime.add(@now, 3600, :second)

      token = %Token{
        token: token_value,
        type: :session,
        expires_at: expires_at,
        consumed_at: nil
      }

      command = %ConsumeToken{token: token_value}

      assert {:error, :not_consumable} = Token.execute(token, command)
    end
  end

  describe "execute/2 - DeleteToken" do
    test "creates TokenDeleted event" do
      token_value = Commanded.UUID.uuid4()

      token = %Token{
        token: token_value,
        type: :session
      }

      command = %DeleteToken{token: token_value}

      assert {:ok, %TokenDeleted{token: ^token_value}} = Token.execute(token, command)
    end
  end

  describe "apply_event/2" do
    test "applies MagicLinkRequested event" do
      token = %Token{token: nil}
      token_value = Commanded.UUID.uuid4()
      expires_at = DateTime.add(@now, 60 * 15, :second)

      event = %MagicLinkRequested{
        token: token_value,
        user_uuid: "user-123",
        email: "test@example.com",
        expires_at: expires_at
      }

      result = Token.apply_event(token, event)

      assert result.token == token_value
      assert result.user_uuid == "user-123"
      assert result.type == :magic_link
      assert result.email == "test@example.com"
      assert result.expires_at == expires_at
    end

    test "applies SessionTokenCreated event" do
      token = %Token{token: nil}
      token_value = Commanded.UUID.uuid4()
      user_uuid = Commanded.UUID.uuid4()
      expires_at = DateTime.add(@now, 60 * 60 * 24 * 7, :second)

      event = %SessionTokenCreated{
        token: token_value,
        user_uuid: user_uuid,
        user_agent: "Mozilla/5.0",
        ip_address: "127.0.0.1",
        expires_at: expires_at
      }

      result = Token.apply_event(token, event)

      assert result.token == token_value
      assert result.user_uuid == user_uuid
      assert result.type == :session
      assert result.expires_at == expires_at
    end

    test "applies TokenConsumed event" do
      token_value = Commanded.UUID.uuid4()
      consumed_at = DateTime.utc_now(:second)

      token = %Token{
        token: token_value,
        type: :magic_link,
        consumed_at: nil
      }

      event = %TokenConsumed{
        token: token_value,
        consumed_at: consumed_at
      }

      result = Token.apply_event(token, event)

      assert result.consumed_at == consumed_at
    end

    test "applies TokenDeleted event" do
      token_value = Commanded.UUID.uuid4()

      token = %Token{
        token: token_value,
        type: :session
      }

      event = %TokenDeleted{token: token_value}

      result = Token.apply_event(token, event)

      assert result.token == nil
    end
  end

  describe "state transitions" do
    test "magic link lifecycle from creation to consumption" do
      # Create magic link
      {:ok, created_event} =
        Token.execute(
          %Token{token: nil},
          %RequestMagicLink{
            email: "test@example.com",
            user_uuid: Commanded.UUID.uuid4()
          }
        )

      created_token = Token.apply_event(%Token{token: nil}, created_event)
      assert created_token.token
      assert created_token.type == :magic_link
      assert created_token.expires_at

      # Consume token
      {:ok, consumed_event} =
        Token.execute(created_token, %ConsumeToken{token: created_token.token})

      consumed_token = Token.apply_event(created_token, consumed_event)
      assert consumed_token.consumed_at
    end

    test "session token lifecycle" do
      user_uuid = Commanded.UUID.uuid4()

      # Create session token
      {:ok, created_event} =
        Token.execute(
          %Token{token: nil},
          %CreateSessionToken{
            user_uuid: user_uuid,
            user_agent: "Mozilla/5.0",
            ip_address: "127.0.0.1"
          }
        )

      session_token = Token.apply_event(%Token{token: nil}, created_event)
      assert session_token.token
      assert session_token.type == :session
      assert session_token.expires_at

      # Delete token
      {:ok, deleted_event} =
        Token.execute(session_token, %DeleteToken{token: session_token.token})

      deleted_token = Token.apply_event(session_token, deleted_event)
      assert deleted_token.token == nil
    end
  end
end
