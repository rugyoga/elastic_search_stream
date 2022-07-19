defmodule ElasticSearchStream do
  @moduledoc """
  Documentation for `ElasticSearchStream`.
  """
  alias ElasticSearchStream.{ES,HTTP,PIT,Query}
    
  @app :elastic_stream_search

  @type json_encoded_string :: binary()

  @type index :: atom()
  @type uri :: binary()

  @no_index nil
  @no_options nil
  @es_max_results ES.max_results


  @spec streamer(ES.query_t()) :: {:ok, Enumerable.t()} | {:error, any}
  def streamer(initial) do
    {:ok,
      initial
      |> search()
      |> Stream.iterate(fn previous -> search(Query.update(initial, previous)) end)}
  rescue
    error -> {:error, error}
  end

  @spec stream(ES.query_t(), ES.index_t()) :: {:ok, any()} | {:error, any()}
  def stream(query, index) do
    case count(query, index) do
      {:ok, count} ->
        if count > ES.max_results() do
          stream_many(query, index, count)
        else
          stream_one(query, index)
        end
      error ->
        error
    end
  end

  @spec stream_many(ES.query_t(), ES.index_t(), non_neg_integer()) ::
          {:error, any()} | {:ok, any()}
  def stream_many(query, index, count) do
    case PIT.create(index) do
      {:ok, pit_id} ->
        try do
          case pit_id |> Query.initial(query) |> streamer() do
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

  @spec stream_one(ES.query_t(), ES.index_t()) :: {:ok, any()} | {:error, any()}
  def stream_one(query, index) do
    query
    |> search(index)
    |> HTTP.on_200(fn body -> body["hits"]["hits"] end)
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

  @spec search(ES.query_t(), ES.index_t() | nil) :: ES.response_t()
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
      HTTP.generate_url("_search", index, HTTP.no_options()),
      payload,
      HTTP.json_encoding()
    )
  end

  @spec count(ES.query_t(), ES.index_t()) :: {:ok, non_neg_integer()} | {:error, any()}
  def count(query, index) do
    :post
    |> HTTP.request(
      HTTP.generate_url("_count", index, HTTP.no_options()),
      Poison.encode!(%{query: query}),
      HTTP.json_encoding()
    )
    |> HTTP.on_200(& &1["count"])
  end
end
