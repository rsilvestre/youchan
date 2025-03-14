# Youchan

A tool to retrieve channel details from YouTube. Youchan allows you to easily fetch channel metadata (title, description, subscribers, views, etc.) from YouTube using the official YouTube Data API.

## Installation

Add `youchan` to the list of dependencies inside `mix.exs`:

```elixir
def deps do
  [
    {:youchan, "~> 0.1.0"}
  ]
end
```

This package requires Elixir 1.15 or later and has the following dependencies:
- poison ~> 6.0 (JSON parsing)
- httpoison ~> 2.2 (HTTP client)
- typed_struct ~> 0.3 (Type definitions)
- nimble_options ~> 1.0 (Option validation)

## YouTube API Key Setup

Youchan uses the official YouTube Data API to fetch channel details. You'll need to obtain an API key from the Google Cloud Console by following these steps:

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the "YouTube Data API v3" for your project
4. Create an API key in the "Credentials" section
5. Set up the API key in one of the following ways:

### Environment Variable (recommended)

```bash
export YOUTUBE_API_KEY=your_api_key_here
```

### Application Configuration

```elixir
# In config/config.exs
config :youchan, 
  youtube_api_key: "your_api_key_here"
```

**Note**: Be careful not to commit your API key to version control. Consider using environment variables or a secrets management solution in production.

## Usage

### Search for Channels

**Youchan.list_channels(query)**

Searches for YouTube channels matching a query string.

```elixir
Youchan.list_channels("elixir programming")

{:ok, [
  %{
    channel_id: "UChbS_z6KHQiIu9et38O37eQ",
    title: "Elixir Mentor",
    description: "Welcome! I'm Jacob Luetzow, an Elixir Developer sharing my passion for functional programming and web development. Through ...",
    published_at: "2022-07-28T17:16:55Z",
    thumbnail_url: "https://yt3.ggpht.com/fJ4V85ujL_2GiYxCU4BC8hAznu21_byedQHbyXQ3-AsiXqcjOyVqzyZ3wnTiQdzypAI_AgATlQ=s800-c-k-c0xffffffff-no-rj-mo"
  },
  %{
    channel_id: "UCadzzZR8N350WXLcDWf0Eug",
    title: "Elixirprogrammer",
    description: "Programming, software development and ELIXIR.",
    published_at: "2020-10-29T22:21:27Z",
    thumbnail_url: "https://yt3.ggpht.com/DIY9yimEcLFm6aIrwJKTFdamtd2WTTg7mGc7cE0VkQpZyTIr-NqJb9B34OWddEmgZgHrKcBH7A=s800-c-k-c0xffffffff-no-rj-mo"
  },
  # ...more results
]}
```

This function returns a simplified list of channel data. To get complete details for a channel, use the `channel_id` with `get_channel_details/1`.

### Get Channel Details

**Youchan.get_channel_details(channel_id)**

Retrieves detailed information about a YouTube channel.

```elixir
Youchan.get_channel_details("UC0l2QTnO1P2iph-86HHilMQ")

{:ok,
 %Youchan.ChannelDetails{
   id: "UC0l2QTnO1P2iph-86HHilMQ",
   title: "ElixirConf",
   description: "The Elixir Community's premier conference for Elixir developers and enthusiasts from around the globe.",
   custom_url: "@elixirconf",
   published_at: "2017-09-07T14:22:45Z",
   country: "US",
   view_count: 1247819,
   subscriber_count: 12100,
   video_count: 408,
   thumbnail_url: "https://yt3.ggpht.com/WqM3hx0p1aXVne5scBpdYNqWGE_nweNVVyj0Wfp2jAPGkC5rojIF2GdL14DRIxKAQLk6k4fpMw=s800-c-k-c0x00ffffff-no-rj",
   topic_categories: [
     "https://en.wikipedia.org/wiki/Technology",
     "https://en.wikipedia.org/wiki/Knowledge",
     "https://en.wikipedia.org/wiki/Lifestyle_(sociology)"
   ],
   keywords: ["elixir phoenix liveview programming development conferences"],
   banner_url: "",
   is_verified: true
 }}
```

**Youchan.get_channel_details_by_username(username)**

Retrieves channel details using a YouTube username.

```elixir
Youchan.get_channel_details_by_username("elixirconf")
```

### Error Handling

All functions return either:
- `{:ok, result}` for successful operations
- `{:error, reason}` when something goes wrong (typically `:not_found`)

### Bang Functions

If you don't need to pattern match `{:ok, data}` and `{:error, reason}`, there is also a trailing bang version that raises an exception on error:

```elixir
# Returns the channel details directly or raises an exception
channel_details = Youchan.get_channel_details!("UC0l2QTnO1P2iph-86HHilMQ")

# Returns the list of channels directly or raises an exception
channels = Youchan.list_channels!("elixir programming")
```

## Formatting Helpers

Youchan provides helper functions for formatting channel data:

```elixir
# Format subscriber count
Youchan.ChannelDetails.format_subscriber_count(channel_details) # => "25K"

# Format view count
Youchan.ChannelDetails.format_view_count(channel_details) # => "1.25M" 

# Format date
Youchan.ChannelDetails.format_date(channel_details) # => "Jun 24, 2014"
```

## Caching

Youchan includes a flexible caching mechanism to improve performance and reduce API calls to YouTube.
The cache system supports multiple backend options:

- **Memory**: In-memory cache using ETS tables (default, fast but not persistent)
- **Disk**: Persistent local storage using DETS (survives application restarts)
- **S3**: Cloud storage using AWS S3 (survives restarts and shareable across instances)
- **Cachex**: Distributed caching using Cachex (supports horizontal scaling across multiple nodes)

### Using Caching

If using Youchan as an application (included in your supervision tree), caching is automatically enabled. Otherwise, you need to manually start the cache:

```elixir
# Start cache
Youchan.start()
```

### Cache Configuration

You can configure cache behavior in your config:

```elixir
# In config/config.exs
config :youchan, 
  # General cache settings
  cache_ttl: 86_400_000,                    # TTL (time-to-live) - 1 day in milliseconds (default)
  cache_cleanup_interval: 3_600_000,        # Cleanup interval - every hour (default)
  
  # Configure which backend to use for the channel details cache
  cache_backends: %{
    # Memory backend (default)
    channel_details: %{
      backend: Youchan.Cache.MemoryBackend,
      backend_options: [
        table_name: :channel_details_cache,
        max_size: 1000                      # Max entries in memory
      ]
    }
  }
```

### Cache Operations

```elixir
# Check if cache is enabled
Youchan.use_cache?()

# Clear cache
Youchan.clear_cache()
```

When caching is enabled, channel details are stored with a TTL (time-to-live). The cache is automatically cleaned up periodically to prevent storage issues.

## Data Structure

### Youchan.ChannelDetails

The channel details structure containing:
- `id`: YouTube channel ID
- `title`: Channel title/name
- `description`: Channel description
- `custom_url`: Custom URL handle (if set)
- `published_at`: Channel creation date (ISO 8601 format)
- `country`: Country code for the channel
- `view_count`: Total number of channel views
- `subscriber_count`: Number of subscribers
- `video_count`: Number of uploaded videos
- `thumbnail_url`: URL to the channel profile image
- `topic_categories`: List of topic categories
- `keywords`: List of keywords associated with the channel
- `banner_url`: URL to channel banner image
- `is_verified`: Whether the channel is verified

**Helper Functions:**
- `format_subscriber_count/1`: Formats subscriber count with K/M/B suffixes
- `format_view_count/1`: Formats view count with K/M/B suffixes
- `format_date/1`: Formats ISO date as human-readable text

## Examples

### Searching for Channels and Getting Details

```elixir
defmodule ChannelFinder do
  def find_and_display_channel(search_term) do
    case Youchan.list_channels(search_term) do
      {:ok, []} ->
        "No channels found for '#{search_term}'"
        
      {:ok, channels} ->
        # Display the first 3 channels found
        IO.puts("Found #{length(channels)} channels matching '#{search_term}':\n")
        
        channels
        |> Enum.take(3)
        |> Enum.map(&display_channel_summary/1)
        |> Enum.join("\n\n")
        
      {:error, reason} ->
        "Error searching for channels: #{reason}"
    end
  end
  
  def display_channel_summary(%{channel_id: id, title: title, description: desc, published_at: published}) do
    # Get full details for the channel
    case Youchan.get_channel_details(id) do
      {:ok, details} ->
        """
        Channel: #{title} #{if details.custom_url != "", do: "(@#{details.custom_url})", else: ""}
        Description: #{String.slice(desc, 0, 100)}#{if String.length(desc) > 100, do: "...", else: ""}
        Subscribers: #{Youchan.ChannelDetails.format_subscriber_count(details)}
        Videos: #{details.video_count}
        Total Views: #{Youchan.ChannelDetails.format_view_count(details)}
        Created: #{Youchan.ChannelDetails.format_date(details)}
        """
        
      {:error, _} ->
        "#{title} - Could not fetch full details"
    end
  end
end

# Usage:
ChannelFinder.find_and_display_channel("elixir programming")

# Sample output:
# Found 5 channels matching 'elixir programming':
#
# Channel: Elixir Mentor
# Description: Welcome! I'm Jacob Luetzow, an Elixir Developer sharing my passion for functional programming and...
# Subscribers: 2.3K 
# Videos: 34
# Total Views: 72.1K
# Created: Jul 28, 2022
#
# Channel: Elixirprogrammer 
# Description: Programming, software development and ELIXIR.
# Subscribers: 242
# Videos: 35
# Total Views: 8.2K
# Created: Oct 29, 2020
```

### Displaying Channel Information

```elixir
defmodule ChannelProcessor do
  def print_channel_summary(channel_id) do
    case Youchan.get_channel_details(channel_id) do
      {:ok, details} ->
        """
        Channel: #{details.title} #{if details.custom_url != "", do: "(@#{details.custom_url})", else: ""}
        Description: #{String.slice(details.description, 0, 100)}
        Subscribers: #{Youchan.ChannelDetails.format_subscriber_count(details)}
        Videos: #{details.video_count}
        Total Views: #{Youchan.ChannelDetails.format_view_count(details)}
        Created: #{Youchan.ChannelDetails.format_date(details)}
        Country: #{details.country}
        """
      
      {:error, reason} -> 
        "Error: #{reason}"
    end
  end
end

# Usage:
summary = ChannelProcessor.print_channel_summary("UC0l2QTnO1P2iph-86HHilMQ")
IO.puts(summary)

# Output:
# Channel: ElixirConf (@elixirconf)
# Description: The Elixir Community's premier conference for Elixir developers and enthusiasts from around the globe.
# Subscribers: 12.1K
# Videos: 408
# Total Views: 1.2M
# Created: Sep 07, 2017
# Country: US
```

## License

MIT License