defmodule TdBg.Taxonomies.Tree do
  @moduledoc """
  Module for tree operations on the Taxonomy.
  """
  import Ecto.Query

  alias Graph.Traversal
  alias TdBg.Repo
  alias TdBg.Taxonomies.Domain

  def graph do
    Domain
    |> where([d], is_nil(d.deleted_at))
    |> select([d], map(d, [:id, :parent_id, :name]))
    |> order_by([d], asc_nulls_first: :parent_id, asc: :id)
    |> Repo.all()
    |> Enum.reduce(Graph.new([], acyclic: true), &reduce_domains/2)
  end

  def ancestor_ids(g, id) do
    with ids <- reaching(g, [id]),
         sg <- Graph.subgraph(g, ids, reverse: true),
         [_ | _] = ids <- Traversal.topsort(sg) do
      ids
    end
  end

  def ancestor_ids(id) do
    graph()
    |> ancestor_ids(id)
  end

  def descendent_ids(id) do
    graph()
    |> reachable([id])
  end

  defp reduce_domains(%{id: id, name: name, parent_id: nil}, %Graph{} = g) do
    Graph.add_vertex(g, id, name: name)
  end

  defp reduce_domains(%{id: id, name: name, parent_id: parent_id}, %Graph{} = g) do
    g
    |> Graph.add_vertex(id, name: name)
    |> Graph.add_vertex(parent_id)
    |> Graph.add_edge(parent_id, id)
  end

  defp reachable(%Graph{} = g, ids) when is_list(ids), do: Traversal.reachable(ids, g)
  defp reaching(%Graph{} = g, ids) when is_list(ids), do: Traversal.reaching(ids, g)
end
