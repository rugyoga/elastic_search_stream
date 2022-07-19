defmodule ElasticSearchStreamTest do
  use ExUnit.Case
  doctest ElasticSearchStream

  test "greets the world" do
    assert ElasticSearchStream.hello() == :world
  end
end
