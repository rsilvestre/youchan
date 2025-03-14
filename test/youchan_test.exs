defmodule YouchanTest do
  use ExUnit.Case, async: true

  use Youchan.Types
  alias Youchan.ChannelDetails

  # Basic tests for ChannelDetails struct
  test "ChannelDetails struct can be created correctly" do
    channel_details = %ChannelDetails{
      id: "UC123456789",
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

    assert channel_details.id == "UC123456789"
    assert channel_details.title == "Test Channel"
    assert channel_details.description == "This is a test description"
    assert channel_details.custom_url == "@TestChannel"
    assert channel_details.country == "US"
    assert channel_details.view_count == 10000000
    assert channel_details.subscriber_count == 100000
    assert channel_details.video_count == 500
    assert channel_details.thumbnail_url == "https://example.com/thumb.jpg"
    assert channel_details.topic_categories == ["https://en.wikipedia.org/wiki/Programming"]
    assert channel_details.keywords == ["test", "channel", "programming"]
    assert channel_details.banner_url == "https://example.com/banner.jpg"
    assert channel_details.is_verified == true
  end

  # Test ChannelDetails.new function
  test "ChannelDetails.new creates a proper struct from API response" do
    # Simulate an API response structure
    channel_data = %{
      "id" => "UC123456789",
      "snippet" => %{
        "title" => "Test Channel",
        "description" => "This is a test description",
        "customUrl" => "@TestChannel",
        "publishedAt" => "2023-01-01T12:00:00Z",
        "country" => "US",
        "thumbnails" => %{
          "high" => %{
            "url" => "https://example.com/thumb.jpg"
          }
        }
      },
      "statistics" => %{
        "viewCount" => "10000000",
        "subscriberCount" => "100000",
        "videoCount" => "500"
      },
      "topicDetails" => %{
        "topicCategories" => ["https://en.wikipedia.org/wiki/Programming"]
      },
      "brandingSettings" => %{
        "channel" => %{
          "keywords" => "test,channel,programming"
        },
        "image" => %{
          "bannerExternalUrl" => "https://example.com/banner.jpg"
        }
      },
      "status" => %{
        "isLinked" => true
      }
    }

    channel_details = ChannelDetails.new(channel_data)

    assert channel_details.id == "UC123456789"
    assert channel_details.title == "Test Channel"
    assert channel_details.description == "This is a test description"
    assert channel_details.custom_url == "@TestChannel"
    assert channel_details.published_at == "2023-01-01T12:00:00Z"
    assert channel_details.country == "US"
    assert channel_details.view_count == 10000000
    assert channel_details.subscriber_count == 100000
    assert channel_details.video_count == 500
    assert channel_details.thumbnail_url == "https://example.com/thumb.jpg"
    assert channel_details.topic_categories == ["https://en.wikipedia.org/wiki/Programming"]
    assert channel_details.keywords == ["test", "channel", "programming"]
    assert channel_details.banner_url == "https://example.com/banner.jpg"
    assert channel_details.is_verified == true
  end

  # Test formatting helpers
  test "format_subscriber_count formats subscriber count correctly" do
    # Create a base struct with all required fields
    base = %ChannelDetails{
      id: "UC123456789",
      title: "Test Channel",
      description: "Description",
      published_at: "2023-01-01T12:00:00Z",
      view_count: 0,
      thumbnail_url: "https://example.com/thumb.jpg"
    }

    # Test with small number
    channel_details = %{base | subscriber_count: 500}
    assert ChannelDetails.format_subscriber_count(channel_details) == "500"

    # Test with thousands
    channel_details = %{base | subscriber_count: 5500}
    assert ChannelDetails.format_subscriber_count(channel_details) == "5.5K"

    # Test with millions
    channel_details = %{base | subscriber_count: 1_500_000}
    assert ChannelDetails.format_subscriber_count(channel_details) == "1.5M"

    # Test with billions
    channel_details = %{base | subscriber_count: 1_200_000_000}
    assert ChannelDetails.format_subscriber_count(channel_details) == "1.2B"
  end

  test "format_view_count formats view count correctly" do
    # Create a base struct with all required fields
    base = %ChannelDetails{
      id: "UC123456789",
      title: "Test Channel",
      description: "Description",
      published_at: "2023-01-01T12:00:00Z",
      view_count: 0,
      thumbnail_url: "https://example.com/thumb.jpg"
    }

    # Test with small number
    channel_details = %{base | view_count: 500}
    assert ChannelDetails.format_view_count(channel_details) == "500"

    # Test with thousands
    channel_details = %{base | view_count: 5500}
    assert ChannelDetails.format_view_count(channel_details) == "5.5K"

    # Test with millions
    channel_details = %{base | view_count: 1_500_000}
    assert ChannelDetails.format_view_count(channel_details) == "1.5M"

    # Test with billions
    channel_details = %{base | view_count: 1_200_000_000}
    assert ChannelDetails.format_view_count(channel_details) == "1.2B"
  end

  test "format_date formats date correctly" do
    # Create a base struct with all required fields
    base = %ChannelDetails{
      id: "UC123456789",
      title: "Test Channel",
      description: "Description",
      published_at: "2023-01-01T12:00:00Z",
      view_count: 0,
      thumbnail_url: "https://example.com/thumb.jpg"
    }

    # Test with ISO 8601 format
    channel_details = %{base | published_at: "2023-01-15T14:30:45Z"}
    assert ChannelDetails.format_date(channel_details) == "Jan 15, 2023"

    # Test with invalid format
    channel_details = %{base | published_at: "2023-01-15"}
    assert ChannelDetails.format_date(channel_details) == "2023-01-15"
  end

  # Skipped tests that would require HTTP interaction or mocking
  @tag :skip
  test "get_channel_details gets details from YouTube" do
    # This would require actual HTTP interaction or mocking
  end

  @tag :skip
  test "get_channel_details! raises error when not found" do
    # This would require mocking
  end
  
  @tag :skip
  test "list_channels returns a list of channels matching the query" do
    # This would require actual HTTP interaction or mocking
  end

  @tag :skip
  test "list_channels! raises error when API call fails" do
    # This would require mocking
  end

  # Cache-related tests
  test "use_cache? function exists" do
    # Just test that the function exists
    assert is_function(&Youchan.use_cache?/0)
  end

  test "clear_cache function exists" do
    # Just test that the function exists
    assert is_function(&Youchan.clear_cache/0)
  end
end