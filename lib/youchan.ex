defmodule Youchan do
  @moduledoc """
  Main module with functions to retrieve YouTube channel details.
  """

  use Youchan.Types

  alias Youchan.{Cache, Channel, ChannelDetails}
  alias Youchan.ChannelDetails.Fetch, as: ChannelDetailsFetch

  @doc """
  Starts the Youchan application with caching enabled.
  Call this function when you want to use caching outside
  of a supervision tree.

  ## Options

  * `:backends` - A map of cache backend configurations (optional)
  * `:ttl` - Cache TTL in milliseconds (optional)

  ## Examples

      # Start with default memory backend
      Youchan.start()

      # Start with custom configuration
      Youchan.start(backends: %{
        channel_details: %{
          backend: Youchan.Cache.DiskBackend,
          backend_options: [cache_dir: "my_cache_dir"]
        }
      })
  """
  def start(opts \\ []) do
    # If specific backends are provided, update application env
    if backend_config = Keyword.get(opts, :backends) do
      Application.put_env(:youchan, :cache_backends, backend_config)
    end

    # If TTL is provided, update application env
    if ttl = Keyword.get(opts, :ttl) do
      Application.put_env(:youchan, :cache_ttl, ttl)
    end

    Cache.start_link(Keyword.get(opts, :cache_opts, []))
  end

  @doc """
  Search for YouTube channels by name.
  
  Returns a list of channel results with basic information including:
  - channel_id
  - title
  - description
  - thumbnail_url
  - published_at
  
  ## Examples
  
      iex> Youchan.list_channels("Elixir programming")
      {:ok, [
        %{
          channel_id: "UCw1rQttXkVl0l7DkiX0vE2A",
          title: "Elixir Casts",
          description: "Elixir and Phoenix tutorial videos...",
          published_at: "2016-09-14T21:26:28Z",
          thumbnail_url: "https://yt3.ggpht.com/..."
        },
        # ...more results
      ]}
  
  For complete channel details, use the channel_id with get_channel_details/1.
  """
  @spec list_channels(String.t()) :: {:ok, list(map())} | error
  def list_channels(query) do
    ChannelDetailsFetch.list_channels(query)
  end

  @doc """
  Like `list_channels/1` but raises an exception on error.
  """
  @spec list_channels!(String.t()) :: list(map())
  def list_channels!(query) do
    case list_channels(query) do
      {:ok, channels} -> channels
      {:error, reason} -> raise RuntimeError, message: to_string(reason)
    end
  end

  @doc """
  Gets details for a YouTube channel.
  Returns a ChannelDetails struct with information about the channel.
  """
  @spec get_channel_details(channel_id) :: channel_details_found | error
  def get_channel_details(channel_id) do
    case use_cache?() && Cache.get_channel_details(channel_id) do
      {:miss, nil} ->
        # Not in cache, fetch and cache it
        fetch_and_cache_channel_details(channel_id)

      {:ok, result} ->
        {:ok, result}

      {:error, _reason} = error ->
        error

      _other ->
        # Fallback for unexpected responses
        fetch_and_cache_channel_details(channel_id)
    end
  end

  defp fetch_and_cache_channel_details(channel_id) do
    result =
      channel_id
      |> Channel.new()
      |> ChannelDetailsFetch.channel_details()

    case result do
      {:ok, _} = ok_result ->
        if use_cache?(), do: Cache.put_channel_details(channel_id, ok_result)
        ok_result

      error ->
        error
    end
  end

  @doc """
  Gets details for a YouTube channel by username.
  Returns a ChannelDetails struct with information about the channel.
  """
  @spec get_channel_details_by_username(String.t()) :: channel_details_found | error
  def get_channel_details_by_username(username) do
    # This can't be cached by username directly, since we don't know the channel ID yet
    result = ChannelDetailsFetch.channel_details_by_username(username)

    case result do
      {:ok, channel_details} = ok_result ->
        # Cache the result by channel ID after we get it
        if use_cache?(), do: Cache.put_channel_details(channel_details.id, ok_result)
        ok_result

      error ->
        error
    end
  end

  @doc """
  Gets details for a YouTube channel.
  Like `get_channel_details/1` but raises an exception on error.
  """
  @spec get_channel_details!(channel_id) :: ChannelDetails.t()
  def get_channel_details!(channel_id) do
    case get_channel_details(channel_id) do
      {:ok, channel_details} -> channel_details
      {:error, reason} -> raise RuntimeError, message: to_string(reason)
    end
  end

  @doc """
  Gets details for a YouTube channel by username.
  Like `get_channel_details_by_username/1` but raises an exception on error.
  """
  @spec get_channel_details_by_username!(String.t()) :: ChannelDetails.t()
  def get_channel_details_by_username!(username) do
    case get_channel_details_by_username(username) do
      {:ok, channel_details} -> channel_details
      {:error, reason} -> raise RuntimeError, message: to_string(reason)
    end
  end

  @doc """
  Clears all cached data including channel details.
  """
  def clear_cache do
    if use_cache?() do
      Cache.clear()
    else
      {:error, :cache_not_started}
    end
  end

  @doc """
  Checks if caching is enabled.
  """
  def use_cache? do
    case Process.whereis(Cache) do
      nil -> false
      _pid -> true
    end
  end
end