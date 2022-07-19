defmodule ElasticSearchStream.HTTP do
    alias ElasticSearchStream.ES

    @type uri_t :: binary()

    def no_payload(), do: nil

    @spec headers(binary()) :: [{binary, binary}]
    def headers(content_type) do
      [
        {"Content-Type", "application/#{content_type}"},
        {"Authorization", "Basic #{auth()}"},
        {"Accept-Encoding", "gzip"}
      ]
    end

    @doc """
    Return :ok on 200, :error on everything else
  
      iex> ElasticSearch.on_200(%Req.Response{status: 200, body: "hot"})
      {:ok, "hot"}
  
      iex> ElasticSearch.on_200(%Req.Response{status: 200, body: "hot"}, &(&1 <> "ter"))
      {:ok, "hotter"}
  
      iex> ElasticSearch.on_200("message")
      {:error, "message"}
    """
    def on_200(response, f \\ fn b -> b end)
    def on_200(%_{status: 200, body: body}, f), do: {:ok, f.(body)}
    def on_200(error, _), do: {:error, error}
      
    @spec auth :: binary()
    def auth, do: Base.encode64("#{env(:elastic_username)}:#{env(:elastic_password)}")
  
    @spec generate_url(binary, nil | ES.index_t(), nil | map) :: binary
    def generate_url(endpoint, index_name, options) do
      index_name |> ES.index() |> url(endpoint, options)
    end

    @spec env(atom) :: binary
    def env(var), do: Confex.get_env(:elastic_search_stream, var)

    @spec url(uri_t() | nil, uri_t(), map | nil) :: uri_t()
    def url(nil, endpoint, nil), do: "#{env(:elastic_host)}/#{endpoint}"
    def url(index, endpoint, nil), do: "#{env(:elastic_host)}/#{index}/#{endpoint}"
  
    def url(index, endpoint, options) do
      options
      |> Enum.map_join(",", fn {k, v} -> "#{k}=#{v}" end)
      |> then(&"#{url(index, endpoint, nil)}?#{&1}")
    end
end