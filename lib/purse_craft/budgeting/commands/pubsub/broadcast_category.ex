defmodule PurseCraft.Budgeting.Commands.PubSub.BroadcastCategory do
  @moduledoc """
  Broadcasts category-specific events to subscribed users.
  """

  alias Phoenix.PubSub
  alias PurseCraft.Budgeting.Schemas.Category

  @type message ::
          {:envelope_repositioned, map()}
          | {:envelope_removed, map()}
          | {:envelope_created, map()}
          | {:envelope_updated, map()}
          | {:envelope_deleted, map()}

  @doc """
  Broadcasts a message to all subscribers of a specific category.

  ## Messages

  The following messages are broadcasted:
  - `{:envelope_repositioned, envelope}` - when an envelope is repositioned within or moved to this category
  - `{:envelope_removed, envelope}` - when an envelope is moved out of this category
  - `{:envelope_created, envelope}` - when a new envelope is created in this category
  - `{:envelope_updated, envelope}` - when an envelope in this category is updated
  - `{:envelope_deleted, envelope}` - when an envelope in this category is deleted

  ## Examples

      iex> BroadcastCategory.call(category, {:envelope_repositioned, envelope})
      :ok

      iex> BroadcastCategory.call(category, {:envelope_created, envelope})
      :ok
  """
  @spec call(Category.t(), message()) :: :ok | {:error, term()}
  def call(%Category{external_id: external_id}, message) do
    PubSub.broadcast(
      PurseCraft.PubSub,
      "category:#{external_id}",
      message
    )
  end
end
