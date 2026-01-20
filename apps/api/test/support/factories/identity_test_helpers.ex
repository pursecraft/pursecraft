defmodule PurseCraft.IdentityTestHelpers do
  @moduledoc """
  Test helper functions for Identity context.
  """

  alias PurseCraft.Identity.UserToken

  @doc """
  Overrides the authenticated_at timestamp for a token.
  """
  def identity_user_token_set_authenticated_at(token, authenticated_at) when is_binary(token) do
    import Ecto.Query

    PurseCraft.Repo.update_all(
      from(t in UserToken, where: t.token == ^token),
      set: [authenticated_at: authenticated_at]
    )
  end

  @doc """
  Offsets the token timestamps for testing expiry.
  """
  def identity_user_token_offset_time(token, amount_to_add, unit) do
    import Ecto.Query

    dt = DateTime.add(DateTime.utc_now(:second), amount_to_add, unit)

    PurseCraft.Repo.update_all(
      from(ut in UserToken, where: ut.token == ^token),
      set: [inserted_at: dt, authenticated_at: dt]
    )
  end
end
