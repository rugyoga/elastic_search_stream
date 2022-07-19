defmodule ElasticSearchStream do
  @moduledoc """
  Documentation for `ElasticSearchStream`.
  """
  
    
    @json_encoding "json"
    @app :elastic_stream_search
  
    @type json_encoded_string :: binary()

    @type index :: atom()
    @type uri :: binary()
  
    @no_index nil
    @no_options nil
    @es_max_results ES.max_results

  
    @spec streamer(es_query()) :: {:ok, Enumerable.t()} | {:error, any}
    def streamer(initial) do
      {:ok,
       initial
       |> search()
       |> Stream.iterate(fn previous -> search(Query.update(initial, previous)) end)}
    rescue
      error -> {:error, error}
    end
  
    @spec stream(es_query(), index()) :: {:ok, any()} | {:error, any()}
    def stream(query, index) do
      case count(query, index) do
        {:ok, count} when count > @es_max_results() ->
          stream_many(query, index)
  
        {:ok, _} ->
          stream_one(query, index)
  
        error ->
          error
      end
    end
  
    @spec stream_many(es_query(), index(), non_neg_integer()) ::
            {:error, any()} | {:ok, any()}
    def stream_many(query, index, count) do
      case PIT.create(index) do
        {:ok, pit_id} ->
          try do
            case pit_id |> query(query) |> streamer() do
              {:ok, stream} ->
                stream
                |> Stream.flat_map(& &1.body["hits"]["hits"])
                |> Stream.take(count)
  
              error ->
                error
            end
          after
            PIT.delete(pit_id)
          end
  
        error ->
          error
      end
    rescue
      error -> {:error, error}
    end
  
    @spec stream_one(es_query(), index()) :: {:ok, any()} | {:error, any()}
    def stream_one(query, index) do
      query
      |> search(index)
      |> on_200(fn body -> consumer.(body["hits"]["hits"]) end)
    end
  
    @doc """
    Return modify :ok component, pass on everything else
  
      iex> ElasticSearch.on_ok({:ok, "I suppose"})
      {:ok, "I suppose"}
  
      iex> ElasticSearch.on_ok({:ok, "good"}, &(&1 <> &1))
      {:ok, "goodgood"}
  
      iex> ElasticSearch.on_ok({:error, "message"})
      {:error, "message"}
    """
    def on_ok(v, f \\ fn b -> b end)
    def on_ok({:ok, value}, f), do: {:ok, f.(value)}
    def on_ok(error, _), do: error
  
    @spec search(es_query(), index() | nil) :: es_response()
    def search(query, index \\ HTTP.no_index()) do
      payload =
        if query do
          case Poison.encode(query) do
            {:ok, json} -> json
            _ -> nil
          end
        end
  
      HTTP.request(
        :post,
        generate_url("_search", index, HTTP.no_options()),
        payload,
        HTTP.json_encoding()
      )
    end
  
    @spec count(map(), :atom) :: {:ok, non_neg_integer()} | {:error, any()}
    def count(query, index) do
      :post
      |> HTTP.request(
        HTTP.generate_url("_count", index, HTTP.no_options()),
        Poison.encode!(%{query: query}),
        HTTP.json_encoding()
      )
      |> on_200(& &1["count"])
    end
end
