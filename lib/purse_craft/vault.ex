defmodule PurseCraft.Vault do
  @moduledoc false

  use Cloak.Vault, otp_app: :purse_craft

  @impl GenServer
  def init(config) do
    config =
      Keyword.put(config, :ciphers,
        default: {
          Cloak.Ciphers.AES.GCM,
          tag: "AES.GCM.V1", key: decode_env!("PURSECRAFT_DATA_KEY"), iv_length: 12
        }
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
