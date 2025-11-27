defmodule TdBg.BusinessConcepts.Search.Suggestions do
  @moduledoc """
  Suggestions search engine
  """
  alias TdBg.Auth.Claims
  alias TdBg.BusinessConcept.Search
  alias TdCluster.Cluster.TdDd

  @num_candidates 100
  @k 10
  @similarity 0.60
  @index_type "suggestions"

  def knn(%Claims{} = claims, params) do
    {collection_name, vector} = generate_vector(params)

    params =
      params
      |> default_params()
      |> exclude_concept_ids()
      |> Map.put_new("must", %{
        "current" => true,
        "status" => ["pending_approval", "draft", "rejected", "published"]
      })
      |> Map.put_new("query_vector", vector)
      |> Map.put_new("field", "embeddings.vector_#{collection_name}")

    Search.vector(claims, params, similarity: :cosine)
  end

  defp default_params(params) do
    params
    |> Map.put_new("num_candidates", @num_candidates)
    |> Map.put_new("k", @k)
    |> Map.put_new("similarity", @similarity)
  end

  defp generate_vector(%{"resource" => %{"type" => "structures", "id" => id}} = params) do
    id
    |> TdDd.generate_vector(@index_type, params["collection_name"])
    |> then(fn {:ok, version} -> version end)
  end

  defp exclude_concept_ids(%{"resource" => %{"links" => links}} = params) do
    business_concept_ids = Enum.map(links, & &1["resource_id"])
    Map.put_new(params, "must_not", %{"business_concept_ids" => business_concept_ids})
  end

  defp exclude_concept_ids(params), do: params
end
