defmodule ElasticSearchStream.ES do
    alias ElasticSearchStream.HTTP
    
    @type response_t :: %Req.Response{}
    @type query_t :: map()
    @type index_t :: atom()

    @indexes Application.get_env(:elastic_search_stream, :indexes)

    def max_results(), do: 10_000

    def no_index(), do: nil

    @spec index(index_t() | nil) :: HTTP.uri_t() | nil
    def index(nil), do: nil
    def index(name), do: @indexes[name]
end