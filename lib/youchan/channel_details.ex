defmodule Youchan.ChannelDetails do
  @moduledoc """
  Module representing details of a YouTube channel.

  This module provides a struct and functions for working with YouTube channel metadata
  retrieved from the YouTube Data API.
  """

  use Youchan.Types
  use TypedStruct

  typedstruct enforce: true do
    field :id, channel_id
    field :title, String.t()
    field :description, String.t()
    field :custom_url, String.t(), default: ""
    field :published_at, String.t()
    field :country, String.t(), default: ""
    field :view_count, integer()
    field :subscriber_count, integer(), default: 0
    field :video_count, integer(), default: 0
    field :thumbnail_url, String.t()
    # Additional fields from API
    field :topic_categories, list(String.t()), default: []
    field :keywords, list(String.t()), default: []
    field :banner_url, String.t(), default: ""
    field :is_verified, boolean(), default: false
  end

  @doc """
  Creates a new ChannelDetails struct from the parsed channel details JSON.

  This function handles mapping from the YouTube Data API response
  to a consistently structured ChannelDetails struct.
  """
  def new(channel_details) do
    snippet = Map.get(channel_details, "snippet", %{})
    statistics = Map.get(channel_details, "statistics", %{})
    branding_settings = Map.get(channel_details, "brandingSettings", %{})
    channel_section = Map.get(branding_settings, "channel", %{})
    
    %__MODULE__{
      id: Map.get(channel_details, "id", ""),
      title: Map.get(snippet, "title", ""),
      description: Map.get(snippet, "description", ""),
      custom_url: Map.get(snippet, "customUrl", ""),
      published_at: Map.get(snippet, "publishedAt", ""),
      country: Map.get(snippet, "country", ""),
      view_count: parse_integer(Map.get(statistics, "viewCount", "0")),
      subscriber_count: parse_integer(Map.get(statistics, "subscriberCount", "0")),
      video_count: parse_integer(Map.get(statistics, "videoCount", "0")),
      thumbnail_url: get_thumbnail_url(snippet),
      topic_categories: Map.get(channel_details, "topicDetails", %{}) |> Map.get("topicCategories", []),
      keywords: Map.get(channel_section, "keywords", "")
                |> split_keywords(),
      banner_url: Map.get(branding_settings, "image", %{}) |> Map.get("bannerExternalUrl", ""),
      is_verified: Map.get(channel_details, "status", %{}) |> Map.get("isLinked", false)
    }
  end

  @doc """
  Formats the subscriber count as a human-readable string with K, M, or B suffixes.

  ## Examples

      iex> channel_details = %Youchan.ChannelDetails{subscriber_count: 1250000}
      iex> Youchan.ChannelDetails.format_subscriber_count(channel_details)
      "1.25M"

      iex> channel_details = %Youchan.ChannelDetails{subscriber_count: 8500}
      iex> Youchan.ChannelDetails.format_subscriber_count(channel_details)
      "8.5K"
  """
  def format_subscriber_count(%__MODULE__{subscriber_count: count}) when count >= 1_000_000_000 do
    "#{Float.round(count / 1_000_000_000, 1)}B"
  end

  def format_subscriber_count(%__MODULE__{subscriber_count: count}) when count >= 1_000_000 do
    "#{Float.round(count / 1_000_000, 1)}M"
  end

  def format_subscriber_count(%__MODULE__{subscriber_count: count}) when count >= 1_000 do
    "#{Float.round(count / 1_000, 1)}K"
  end

  def format_subscriber_count(%__MODULE__{subscriber_count: count}) do
    "#{count}"
  end

  @doc """
  Formats the view count as a human-readable string with K, M, or B suffixes.

  ## Examples

      iex> channel_details = %Youchan.ChannelDetails{view_count: 1250000}
      iex> Youchan.ChannelDetails.format_view_count(channel_details)
      "1.25M"

      iex> channel_details = %Youchan.ChannelDetails{view_count: 8500}
      iex> Youchan.ChannelDetails.format_view_count(channel_details)
      "8.5K"
  """
  def format_view_count(%__MODULE__{view_count: count}) when count >= 1_000_000_000 do
    "#{Float.round(count / 1_000_000_000, 1)}B"
  end

  def format_view_count(%__MODULE__{view_count: count}) when count >= 1_000_000 do
    "#{Float.round(count / 1_000_000, 1)}M"
  end

  def format_view_count(%__MODULE__{view_count: count}) when count >= 1_000 do
    "#{Float.round(count / 1_000, 1)}K"
  end

  def format_view_count(%__MODULE__{view_count: count}) do
    "#{count}"
  end

  @doc """
  Formats the publish date in a more readable format.

  ## Example

      iex> channel_details = %Youchan.ChannelDetails{published_at: "2023-01-15T14:30:45Z"}
      iex> Youchan.ChannelDetails.format_date(channel_details)
      "Jan 15, 2023"
  """
  def format_date(%__MODULE__{published_at: date_string}) do
    case DateTime.from_iso8601(date_string) do
      {:ok, date_time, _} ->
        Calendar.strftime(date_time, "%b %d, %Y")

      _ ->
        date_string
    end
  end

  # Private helper functions

  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> 0
    end
  end

  defp parse_integer(value) when is_integer(value), do: value
  defp parse_integer(_), do: 0

  defp get_thumbnail_url(snippet) do
    case Map.get(snippet, "thumbnails", %{}) do
      %{"high" => %{"url" => url}} -> url
      %{"medium" => %{"url" => url}} -> url
      %{"default" => %{"url" => url}} -> url
      _ -> ""
    end
  end
  
  defp split_keywords(""), do: []
  defp split_keywords(nil), do: []
  defp split_keywords(keywords) when is_binary(keywords) do
    String.split(keywords, ",", trim: true)
    |> Enum.map(&String.trim/1)
  end
  defp split_keywords(keywords) when is_list(keywords), do: keywords
end