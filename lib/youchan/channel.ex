defmodule Youchan.Channel do
  @moduledoc """
  The module to create and hold YouTube channel information.
  """

  @base_url "https://www.youtube.com/channel/"

  use Youchan.Types
  use TypedStruct

  typedstruct enforce: true do
    field :id, channel_id
    field :url, String.t()
  end

  def new(id) do
    struct!(__MODULE__, id: id, url: @base_url <> id)
  end
end