defmodule PurseCraft.Utilities.SearchToken do
  @moduledoc """
  Ecto type for deterministic search token encryption.
  Uses HMAC for deterministic hashing instead of random IV encryption.
  """

  use Cloak.Ecto.HMAC, otp_app: :purse_craft

  @impl Cloak.Ecto.HMAC
  def init(config) do
    config =
      Keyword.merge(config,
        algorithm: :sha256,
        secret: decode_env!("PURSECRAFT_SEARCH_KEY")
      )

    {:ok, config}
  end

  defp decode_env!(var) do
    case System.get_env(var) do
      nil ->
        raise "Environment variable #{var} is missing. Generate with: 32 |> :crypto.strong_rand_bytes() |> Base.encode64()"

      key ->
        Base.decode64!(key)
    end
  end
end
