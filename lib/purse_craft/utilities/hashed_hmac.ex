defmodule PurseCraft.Utilities.HashedHMAC do
  @moduledoc """
  Local Ecto type used for creating searchable hashes of sensitive columns.
  """

  use Cloak.Ecto.HMAC, otp_app: :purse_craft

  @impl Cloak.Ecto.HMAC
  def init(config) do
    config =
      Keyword.merge(config,
        algorithm: :sha256,
        secret: decode_env!("PURSECRAFT_HMAC_SECRET")
      )

    {:ok, config}
  end

  defp decode_env!(var) do
    case System.get_env(var) do
      nil ->
        # coveralls-ignore-next-line
        raise "Environment variable #{var} is missing. Generate with: 32 |> :crypto.strong_rand_bytes() |> Base.encode64()"

      key ->
        Base.decode64!(key)
    end
  end
end
