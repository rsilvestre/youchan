defmodule Youchan.Cache.DiskBackendTest do
  use ExUnit.Case

  alias Youchan.Cache.DiskBackend
  alias Youchan.ChannelDetails

  @test_dir "test/tmp/cache"

  setup do
    # Ensure test directory exists
    File.mkdir_p!(@test_dir)

    # Initialize backend with test directory
    {:ok, state} =
      DiskBackend.init(
        table_name: :test_disk_cache,
        cache_dir: @test_dir
      )

    on_exit(fn ->
      # Clean up test files after test
      File.rm_rf!(@test_dir)
    end)

    {:ok, %{state: state}}
  end

  test "stores and retrieves channel details", %{state: state} do
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

    # Store value
    assert :ok = DiskBackend.put(channel_id, channel_details, ttl, state)

    # Retrieve value
    retrieved = DiskBackend.get(channel_id, state)
    assert retrieved.id == channel_details.id
    assert retrieved.title == channel_details.title
    assert retrieved.subscriber_count == channel_details.subscriber_count
    assert retrieved.view_count == channel_details.view_count
  end

  test "returns nil for non-existent keys", %{state: state} do
    assert nil == DiskBackend.get("non_existent", state)
  end

  test "handles expired entries", %{state: state} do
    test_key = "expired_key"
    test_value = %{data: "test_data"}
    # Very short TTL
    ttl = 1

    # Store value with short TTL
    :ok = DiskBackend.put(test_key, test_value, ttl, state)

    # Wait for expiry
    :timer.sleep(10)

    # Should return nil for expired key
    assert nil == DiskBackend.get(test_key, state)
  end

  test "clears all entries", %{state: state} do
    # Add multiple entries
    :ok = DiskBackend.put("key1", "value1", 10_000, state)
    :ok = DiskBackend.put("key2", "value2", 10_000, state)

    # Verify entries exist
    assert "value1" = DiskBackend.get("key1", state)
    assert "value2" = DiskBackend.get("key2", state)

    # Clear all entries
    :ok = DiskBackend.clear(state)

    # Verify entries are gone
    assert nil == DiskBackend.get("key1", state)
    assert nil == DiskBackend.get("key2", state)
  end

  test "deletes entries", %{state: state} do
    :ok = DiskBackend.put("key1", "value1", 10_000, state)
    assert "value1" = DiskBackend.get("key1", state)

    :ok = DiskBackend.delete("key1", state)
    assert nil == DiskBackend.get("key1", state)
  end

  test "cleans up expired entries", %{state: state} do
    # Add an entry that will expire
    :ok = DiskBackend.put("expired", "value", 1, state)
    # Add an entry that won't expire
    :ok = DiskBackend.put("valid", "value", 10_000, state)

    # Wait for first entry to expire
    :timer.sleep(10)

    # Run cleanup
    :ok = DiskBackend.cleanup(state)

    # Expired entry should be gone, valid entry should remain
    assert nil == DiskBackend.get("expired", state)
    assert "value" = DiskBackend.get("valid", state)
  end
end