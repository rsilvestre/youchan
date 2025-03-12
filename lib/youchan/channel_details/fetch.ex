defmodule Youchan.ChannelDetails.Fetch do
  @moduledoc false

  use Youchan.Types

  alias Youchan.HttpClient
  alias Youchan.ChannelDetails

  @youtube_channel_api_url "https://content-youtube.googleapis.com/youtube/v3/channels"
  @youtube_search_api_url "https://content-youtube.googleapis.com/youtube/v3/search"
  @channel_api_parts "brandingSettings,contentDetails,contentOwnerDetails,id,localizations,snippet,statistics,status,topicDetails"
  @search_api_parts "snippet"
  @search_api_fields "items(id/channelId,snippet)"

  @spec channel_details(channel) :: channel_details_found | error
  def channel_details(channel) do
    channel.id
    |> build_channel_api_url()
    |> fetch_from_api()
    |> parse_response()
  end

  @spec channel_details_by_username(String.t()) :: channel_details_found | error
  def channel_details_by_username(username) do
    username
    |> build_channel_api_url_by_username()
    |> fetch_from_api()
    |> parse_response()
  end

  @doc """
  Search for YouTube channels by name.
  
  Returns a list of channel results with limited information including:
  - channel_id
  - title
  - description
  - thumbnail_url
  - published_at
  
  For complete channel details, use the channel_id with get_channel_details/1.
  """
  @spec list_channels(String.t()) :: {:ok, list(map())} | error
  def list_channels(query) do
    query
    |> build_search_api_url()
    |> fetch_from_api()
    |> parse_search_response()
  end

  defp build_channel_api_url(channel_id) do
    api_key = get_api_key()
    "#{@youtube_channel_api_url}?id=#{channel_id}&part=#{@channel_api_parts}&key=#{api_key}"
  end

  defp build_channel_api_url_by_username(username) do
    api_key = get_api_key()
    "#{@youtube_channel_api_url}?forUsername=#{username}&part=#{@channel_api_parts}&key=#{api_key}"
  end

  defp build_search_api_url(query) do
    api_key = get_api_key()
    encoded_query = URI.encode_www_form(query)
    "#{@youtube_search_api_url}?part=#{@search_api_parts}&type=channel&q=#{encoded_query}&fields=#{@search_api_fields}&key=#{api_key}"
  end

  defp get_api_key do
    System.get_env("YOUTUBE_API_KEY") ||
      Application.get_env(:youchan, :youtube_api_key) ||
      raise "YouTube API key not found. Please set the YOUTUBE_API_KEY environment variable or configure it in your application config."
  end

  defp fetch_from_api(url) do
    HttpClient.get(url)
  end

  defp parse_response({:ok, json_body}) do
    case Poison.decode(json_body) do
      {:ok, %{"items" => [item | _]}} ->
        {:ok, ChannelDetails.new(item)}

      {:ok, %{"items" => []}} ->
        {:error, :not_found}

      {:ok, %{"error" => %{"message" => message}}} ->
        {:error, message}

      {:error, _} ->
        {:error, :parse_error}

      _ ->
        {:error, :unknown_error}
    end
  end

  defp parse_response({:error, reason}), do: {:error, reason}

  defp parse_search_response({:ok, json_body}) do
    case Poison.decode(json_body) do
      {:ok, %{"items" => items}} when is_list(items) ->
        {:ok, process_search_results(items)}

      {:ok, %{"items" => []}} ->
        {:ok, []}

      {:ok, %{"error" => %{"message" => message}}} ->
        {:error, message}

      {:error, _} ->
        {:error, :parse_error}

      _ ->
        {:error, :unknown_error}
    end
  end

  defp parse_search_response({:error, reason}), do: {:error, reason}

  defp process_search_results(items) do
    Enum.map(items, fn item ->
      snippet = Map.get(item, "snippet", %{})
      thumbnails = Map.get(snippet, "thumbnails", %{})
      
      %{
        channel_id: get_in(item, ["id", "channelId"]),
        title: Map.get(snippet, "title", ""),
        description: Map.get(snippet, "description", ""),
        published_at: Map.get(snippet, "publishedAt", ""),
        thumbnail_url: get_thumbnail_url(thumbnails)
      }
    end)
  end

  defp get_thumbnail_url(thumbnails) when is_map(thumbnails) do
    cond do
      Map.has_key?(thumbnails, "high") -> get_in(thumbnails, ["high", "url"])
      Map.has_key?(thumbnails, "medium") -> get_in(thumbnails, ["medium", "url"])
      Map.has_key?(thumbnails, "default") -> get_in(thumbnails, ["default", "url"])
      true -> ""
    end
  end
  
  defp get_thumbnail_url(_), do: ""
end