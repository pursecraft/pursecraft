defmodule PurseCraft.Identity.Schemas.UserToken do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Query

  alias __MODULE__
  alias PurseCraft.Identity.Schemas.User
  alias PurseCraft.Utilities.EncryptedBinary
  alias PurseCraft.Utilities.HashedHMAC

  @hash_algorithm :sha256
  @rand_size 32

  # It is very important to keep the magic link token expiry short,
  # since someone with access to the email may take over the account.
  @magic_link_validity_in_minutes 15
  @change_email_validity_in_days 7
  @session_validity_in_days 60

  @type t :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          token: binary() | nil,
          context: String.t() | nil,
          sent_to: String.t() | nil,
          sent_to_hash: binary() | nil,
          user_id: integer() | nil,
          inserted_at: DateTime.t() | nil
        }

  schema "users_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, EncryptedBinary
    field :sent_to_hash, HashedHMAC
    belongs_to :user, User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @spec rand_size() :: integer()
  def rand_size, do: @rand_size

  @doc """
  Generates a token that will be stored in a signed place,
  such as session or cookie. As they are signed, those
  tokens do not need to be hashed.

  The reason why we store session tokens in the database, even
  though Phoenix already provides a session cookie, is because
  Phoenix' default session cookies are not persisted, they are
  simply signed and potentially encrypted. This means they are
  valid indefinitely, unless you change the signing/encryption
  salt.

  Therefore, storing them allows individual user
  sessions to be expired. The token system can also be extended
  to store additional data, such as the device used for logging in.
  You could then use this information to display all valid sessions
  and devices in the UI and allow users to explicitly expire any
  session they deem invalid.
  """
  @spec build_session_token(User.t()) :: {binary(), t()}
  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(rand_size())
    {token, %UserToken{token: token, context: "session", user_id: user.id}}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user found by the token, if any.

  The token is valid if it matches the value in the database and it has
  not expired (after @session_validity_in_days).
  """
  @spec verify_session_token_query(binary) :: {:ok, Ecto.Query.t()}
  def verify_session_token_query(token) do
    query =
      from token in by_token_and_context_query(token, "session"),
        join: user in assoc(token, :user),
        where: token.inserted_at > ago(@session_validity_in_days, "day"),
        select: user,
        select_merge: %{authenticated_at: token.inserted_at}

    {:ok, query}
  end

  @doc """
  Builds a token and its hash to be delivered to the user's email.

  The non-hashed token is sent to the user email while the
  hashed part is stored in the database. The original token cannot be reconstructed,
  which means anyone with read-only access to the database cannot directly use
  the token in the application to gain access. Furthermore, if the user changes
  their email in the system, the tokens sent to the previous email are no longer
  valid.

  Users can easily adapt the existing code to provide other types of delivery methods,
  for example, by phone numbers.
  """
  @spec build_email_token(User.t(), String.t()) :: {binary(), t()}
  def build_email_token(user, context) do
    build_hashed_token(user, context, user.email)
  end

  defp build_hashed_token(user, context, sent_to) do
    token = :crypto.strong_rand_bytes(rand_size())
    hashed_token = :crypto.hash(@hash_algorithm, token)

    user_token = put_hashed_fields(%UserToken{token: hashed_token, context: context, sent_to: sent_to, user_id: user.id})

    {Base.url_encode64(token, padding: false), user_token}
  end

  @doc """
  Sets the sent_to_hash field based on the sent_to field.
  """
  @spec put_hashed_fields(t()) :: t()
  def put_hashed_fields(%UserToken{sent_to: nil} = user_token), do: user_token

  def put_hashed_fields(%UserToken{sent_to: sent_to} = user_token) when is_binary(sent_to) do
    %{user_token | sent_to_hash: String.downcase(sent_to)}
  end

  # coveralls-ignore-next-line
  def put_hashed_fields(user_token), do: user_token

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  If found, the query returns a tuple of the form `{user, token}`.

  The given token is valid if it matches its hashed counterpart in the
  database. This function also checks if the token is being used within
  15 minutes. The context of a magic link token is always "login".
  """
  @spec verify_magic_link_token_query(binary()) :: {:ok, Ecto.Query.t()} | :error
  def verify_magic_link_token_query(token) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in by_token_and_context_query(hashed_token, "login"),
            join: user in assoc(token, :user),
            where: token.inserted_at > ago(^@magic_link_validity_in_minutes, "minute"),
            select: {user, token}

        {:ok, query}

      :error ->
        :error
    end
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user_token found by the token, if any.

  This is used to validate requests to change the user
  email.
  The given token is valid if it matches its hashed counterpart in the
  database and if it has not expired (after @change_email_validity_in_days).
  The context must always start with "change:".
  """
  @spec verify_change_email_token_query(binary(), String.t()) :: {:ok, Ecto.Query.t()} | :error
  def verify_change_email_token_query(token, "change:" <> _object = context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in by_token_and_context_query(hashed_token, context),
            where: token.inserted_at > ago(@change_email_validity_in_days, "day")

        {:ok, query}

      # coveralls-ignore-start
      :error ->
        :error
        # coveralls-ignore-stop
    end
  end

  @doc """
  Returns the token struct for the given token value and context.
  """
  @spec by_token_and_context_query(binary(), String.t()) :: Ecto.Query.t()
  def by_token_and_context_query(token, context) do
    from UserToken, where: [token: ^token, context: ^context]
  end

  @doc """
  Gets all tokens for the given user for the given contexts.
  """
  @spec by_user_and_contexts_query(User.t(), atom() | list(String.t())) :: Ecto.Query.t()
  def by_user_and_contexts_query(user, :all) do
    from t in UserToken, where: t.user_id == ^user.id
  end

  def by_user_and_contexts_query(user, [_head | _tail] = contexts) do
    from t in UserToken, where: t.user_id == ^user.id and t.context in ^contexts
  end

  @doc """
  Deletes a list of tokens.
  """
  @spec delete_all_query(list(binary())) :: Ecto.Query.t()
  def delete_all_query(tokens) do
    from t in UserToken, where: t.id in ^Enum.map(tokens, & &1.id)
  end
end
