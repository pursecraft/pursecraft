defmodule PurseCraft.Types do
  @moduledoc """
  Shared type definitions for the PurseCraft application.
  """

  @type preload_item :: atom() | {atom(), preload_item()} | [preload_item()]
  @type preload :: preload_item() | [preload_item()]
end
