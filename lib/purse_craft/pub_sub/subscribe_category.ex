defmodule PurseCraft.PubSub.SubscribeCategory do
  @moduledoc """
  Subscribes to notifications about changes for a specific category.
  """

  alias Phoenix.PubSub

  @doc """
  Subscribes to notifications about changes for a specific category.

  The broadcasted messages match the pattern:

    * {:envelope_repositioned, envelope}
    * {:envelope_removed, envelope}
    * {:envelope_created, envelope}
    * {:envelope_updated, envelope}
    * {:envelope_deleted, envelope}

  ## Examples

      iex> SubscribeCategory.call("01234567-89ab-cdef-0123-456789abcdef")
      :ok

  """
  @spec call(Ecto.UUID.t()) :: :ok | {:error, term()}
  def call(category_external_id) do
    PubSub.subscribe(PurseCraft.PubSub, "category:#{category_external_id}")
  end
end