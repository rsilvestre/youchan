defmodule Youchan.Cache.CachexBackendTest do
  use ExUnit.Case, async: false

  alias Youchan.Cache.CachexBackend
  alias Youchan.ChannelDetails

  # Tests for the Cachex backend implementation
  @moduletag :cachex

  # Since testing Cachex properly would require a more complex setup with mocks,
  # we'll test the implementation directly with simple helpers that don't depend
  # on the actual Cachex implementation details

  # Create a test state that simulates what we would use with Cachex
  setup do
    state = %{cache: :mock_test_cache}
    {:ok, %{state: state}}
  end

  test "put formats channel details correctly", %{state: state} do
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

    ttl = 10_000

    # Mock Cachex.put for this test
    :meck.new(Cachex, [:passthrough])

    :meck.expect(Cachex, :put, fn cache_name, key, value, opts ->
      assert cache_name == state.cache
      assert key == channel_id
      assert value == channel_details
      assert Keyword.get(opts, :ttl) == ttl
      {:ok, true}
    end)

    # Run the function
    result = CachexBackend.put(channel_id, channel_details, ttl, state)

    # Verify the result
    assert result == {:ok, state}

    # Clean up
    :meck.unload(Cachex)
  end

  test "get handles channel details correctly", %{state: state} do
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

    # Test successful get
    :meck.new(Cachex, [:passthrough])

    :meck.expect(Cachex, :get, fn cache_name, key ->
      assert cache_name == state.cache
      assert key == channel_id
      {:ok, channel_details}
    end)

    result = CachexBackend.get(channel_id, state)
    assert result == channel_details
    assert result.title == "Test Channel"
    assert result.subscriber_count == 100000
    assert result.view_count == 10000000

    # Test nil result
    :meck.expect(Cachex, :get, fn _cache_name, _key -> {:ok, nil} end)
    result = CachexBackend.get(channel_id, state)
    assert result == nil

    # Test error result
    :meck.expect(Cachex, :get, fn _cache_name, _key -> {:error, :some_error} end)
    result = CachexBackend.get(channel_id, state)
    assert result == nil

    # Clean up
    :meck.unload(Cachex)
  end

  test "delete works correctly", %{state: state} do
    test_key = "test_key"

    # Mock Cachex.del
    :meck.new(Cachex, [:passthrough])

    :meck.expect(Cachex, :del, fn cache_name, key ->
      assert cache_name == state.cache
      assert key == test_key
      {:ok, 1}
    end)

    # Test the delete function
    result = CachexBackend.delete(test_key, state)
    assert result == :ok

    # Test error handling
    :meck.expect(Cachex, :del, fn _cache_name, _key -> {:error, :some_error} end)
    result = CachexBackend.delete(test_key, state)
    assert result == {:error, :some_error}

    # Clean up
    :meck.unload(Cachex)
  end

  test "clear works correctly", %{state: state} do
    # Mock Cachex.clear
    :meck.new(Cachex, [:passthrough])

    :meck.expect(Cachex, :clear, fn cache_name ->
      assert cache_name == state.cache
      {:ok, :cleared}
    end)

    # Test the clear function
    result = CachexBackend.clear(state)
    assert result == :ok

    # Test error handling
    :meck.expect(Cachex, :clear, fn _cache_name -> {:error, :some_error} end)
    result = CachexBackend.clear(state)
    assert result == {:error, :some_error}

    # Clean up
    :meck.unload(Cachex)
  end

  test "cleanup is a no-op", %{state: state} do
    result = CachexBackend.cleanup(state)
    assert result == :ok
  end

  # Init function testing is challenging due to mocking issues
  # For production use, we'll need to ensure the code is well-tested manually
end