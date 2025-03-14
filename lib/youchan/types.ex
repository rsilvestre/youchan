defmodule Youchan.Types do
  @moduledoc false

  alias Youchan.Channel
  alias Youchan.ChannelDetails

  defmacro __using__(_opts) do
    quote do
      @type channel :: Channel.t()
      @type channel_id :: String.t()

      @type channel_details_found :: {:ok, ChannelDetails.t()}
      @type error :: {:error, :not_found} | {:error, String.t()}
    end
  end
end