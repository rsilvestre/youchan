defmodule Youchan.CacheTest do
  use ExUnit.Case
  alias Youchan.{Cache, ChannelDetails}

  setup do
    # Start cache for testing or use existing
    case Process.whereis(Cache) do
      nil ->
        # Choose backend based on available dependencies (MemoryBackend or CachexBackend)
        backend =
          if Code.ensure_loaded?(Cachex) do
            Youchan.Cache.CachexBackend
          else
            Youchan.Cache.MemoryBackend
          end

        opts = [
          backends: %{
            channel_details: %{
              backend: backend,
              backend_options: [table_name: :test_channel_details]
            }
          }
        ]

        {:ok, _pid} = Cache.start_link(opts)

      _pid ->
        :ok
    end

    # Clear cache before each test
    Cache.clear()

    # Pass the backend type used to tests
    backend_type =
      if Code.ensure_loaded?(Cachex) do
        :cachex
      else
        :memory
      end

    {:ok, %{backend_type: backend_type}}
  end

  test "caches and retrieves channel details" do
    channel_id = "UC123456789"

    channel_details = %ChannelDetails{
      id: channel_id,
      title: "Test Channel",
      description: "This is a test description",
      custom_url: "@TestChannel",
      published_at: "2023-01-01T12:00:00Z",
      country: "US",
      view_count: 10000000,
      subscriber_count: 100000,
      video_count: 500,
      thumbnail_url: "https://example.com/thumb.jpg",
      topic_categories: ["https://en.wikipedia.org/wiki/Programming"],
      keywords: ["test", "channel", "programming"],
      banner_url: "https://example.com/banner.jpg",
      is_verified: true
    }

    # Cache the channel details
    Cache.put_channel_details(channel_id, {:ok, channel_details})

    # Retrieve from cache
    case Cache.get_channel_details(channel_id) do
      {:ok, cached_details} ->
        assert cached_details == channel_details

      other ->
        flunk("Expected {:ok, details}, got: #{inspect(other)}")
    end
  end

  test "returns {:miss, nil} for non-existent items" do
    assert Cache.get_channel_details("non_existent_id") == {:miss, nil}
  end

  test "clear removes all cached items" do
    channel_id = "UC123456789"

    channel_details = %ChannelDetails{
      id: channel_id,
      title: "Test Channel",
      description: "This is a test description",
      custom_url: "@TestChannel",
      published_at: "2023-01-01T12:00:00Z",
      country: "US",
      view_count: 10000000,
      subscriber_count: 100000,
      video_count: 500,
      thumbnail_url: "https://example.com/thumb.jpg"
    }

    Cache.put_channel_details(channel_id, {:ok, channel_details})

    # Verify cache has the item
    case Cache.get_channel_details(channel_id) do
      {:ok, cached_details} ->
        assert cached_details == channel_details

      other ->
        flunk("Expected {:ok, details}, got: #{inspect(other)}")
    end

    # Clear cache
    Cache.clear()

    # Verify item is gone
    assert Cache.get_channel_details(channel_id) == {:miss, nil}
  end

  @tag :cachex
  test "runs with Cachex backend if available", %{backend_type: backend_type} do
    # Skip if Cachex is not available
    if backend_type != :cachex do
      # Just return early from the test if Cachex isn't available
      IO.puts("Skipping Cachex test - Cachex not available")
      assert true
    else
      # This test verifies that the code can run using the Cachex backend
      # by storing and retrieving a value
      channel_id = "cachex_test_channel"

      channel_details = %ChannelDetails{
        id: channel_id,
        title: "Test Channel",
        description: "This is a test description",
        custom_url: "@TestChannel",
        published_at: "2023-01-01T12:00:00Z",
        country: "US",
        view_count: 10000000,
        subscriber_count: 100000,
        video_count: 500,
        thumbnail_url: "https://example.com/thumb.jpg"
      }

      # Cache the channel details
      Cache.put_channel_details(channel_id, {:ok, channel_details})

      # Retrieve from cache
      case Cache.get_channel_details(channel_id) do
        {:ok, cached_details} ->
          assert cached_details == channel_details

        other ->
          flunk("Expected {:ok, details}, got: #{inspect(other)}")
      end
    end
  end
end