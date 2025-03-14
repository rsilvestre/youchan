defmodule Youchan.Cache do
  @moduledoc """
  Provides caching functionality for YouTube channel data to reduce API calls to YouTube.

  This module uses YouCache internally while maintaining the original API.
  """

  use YouCache,
    registries: [:channel_details]

  use Youchan.Types

  alias Youchan.ChannelDetails

  # Default TTL of 1 day in milliseconds
  @default_ttl 86_400_000

  # Public API

  @doc """
  Gets channel details from cache or returns nil if not found.
  """
  @spec get_channel_details(channel_id) :: {:ok, ChannelDetails.t()} | {:miss, nil} | {:error, term()}
  def get_channel_details(channel_id) do
    get(:channel_details, channel_id)
  end

  @doc """
  Caches channel details for a channel ID.
  """
  @spec put_channel_details(channel_id, {:ok, ChannelDetails.t()}) :: {:ok, ChannelDetails.t()}
  def put_channel_details(channel_id, {:ok, channel_details} = data) do
    ttl = get_ttl()
    # Store just the channel details, not the full {:ok, details} tuple
    put(:channel_details, channel_id, channel_details, ttl)
    data
  end

  # Helper function to maintain original behavior
  defp get_ttl do
    Application.get_env(:youchan, :cache_ttl, @default_ttl)
  end
end