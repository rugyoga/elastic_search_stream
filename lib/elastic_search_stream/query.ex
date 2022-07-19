defmodule ElasticSearchStream.Query do
    alias ElasticSearchStream.{ES, PIT}

    @spec update(ES.query_t(), ES.response_t()) :: ES.query_t()
    def update(
            query,
            %Req.Response{body: %{"hits" => %{"hits" => hits}}, status: 200}
        ) do
        Map.put(query, :search_after, List.last(hits)["sort"])
    end

    @spec initial(PIT.pit_t(), ES.query_t()) :: ES.query_t()
    def initial(pit, query) do
        %{
            query: query,
            pit: %{id: pit, keep_alive: PIT.expiration()},
            size: ES.max_results(),
            sort: %{"_shard_doc" => "desc"}
        }
    end
end