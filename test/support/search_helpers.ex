defmodule SearchHelpers do
  @moduledoc """
  Helper functions for mocking search responses.
  """

  def expect_bulk_index(n \\ 1) do
    ElasticsearchMock
    |> Mox.expect(:request, n, fn _, :post, "/concepts/_doc/_bulk", _, [] ->
      bulk_index_response()
    end)
  end

  def bulk_index_response do
    {:ok, %{"errors" => false, "items" => [], "took" => 0}}
  end

  def hits_response(bcvs, total \\ nil) do
    docs =
      bcvs
      |> TdBg.Repo.preload(business_concept: [:domain, :shared_to])
      |> Enum.map(&encode/1)

    total = total || Enum.count(docs)
    {:ok, %{"hits" => %{"hits" => docs, "total" => %{"relation" => "eq", "value" => total}}}}
  end

  def scroll_response(hits, total \\ nil) do
    {:ok, resp} = hits_response(hits, total)
    {:ok, Map.put(resp, "_scroll_id", "some_scroll_id")}
  end

  def search_after_response(hits) do
    {:ok, resp} = hits_response(hits)
    {:ok, Map.put(resp, "pit_id", "foo")}
  end

  defp encode(target) do
    id = Elasticsearch.Document.id(target)

    source =
      target
      |> Elasticsearch.Document.encode()
      |> Jason.encode!()
      |> Jason.decode!()

    %{"id" => id, "_source" => source, "sort" => ["search after cursor"], "_score" => 1.0}
  end
end
