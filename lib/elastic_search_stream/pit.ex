defmodule ElasticSearchStream.PIT do
  alias ElasticSearchStream.{ES,HTTP}

  @expiration "1m"
  @type pit_t :: binary()

  @spec create(ES.index_t()) :: {:ok, pit_t()} | {:error, ES.response_t()}
  def create(index) do
    :post
    |> HTTP.request(url(index), HTTP.no_payload(), HTTP.json_encoding())
    |> HTTP.on_200(& &1["id"])
  end

  @spec url(ES.index_t()) :: HTTP.uri_t()
  defp url(index) do
    HTTP.generate_url("_pit", index, %{keep_alive: @expiration})
  end

  @spec delete(pit_t()) ::
          :ok | {:error, HTTPoison.AsyncResponse | HTTPoison.MaybeRedirect | HTTPoison.Response}
  def delete(pit) do
    url = HTTP.generate_url("_pit", ES.no_index(), HTTP.no_options())

    with {:ok, payload} <- Poison.encode(%{"id" => pit}),
          %HTTPoison.Response{status_code: 200} <-
            HTTPoison.request!(:delete, url, payload, HTTP.headers(HTTP.json_encoding())) do
      :ok
    else
      error -> {:error, error}
    end
  end
end