defmodule TdBg.Taxonomies.TreeTest do
  use TdBg.DataCase

  import TdBg.TestOperators

  alias TdBg.Taxonomies.Tree

  setup do
    parent = insert(:domain)
    children = Enum.map(1..5, fn _ -> insert(:domain, parent: parent) end)
    Enum.each(1..3, fn _ -> insert(:domain, parent: parent, deleted_at: DateTime.utc_now()) end)
    assert _graph = %Graph{} = Tree.graph()
    [parent: parent, children: children]
  end

  describe "graph/0" do
    test "returns a graph of non-deleted domains", %{parent: parent, children: children} do
      assert graph = %Graph{} = Tree.graph()
      assert Graph.no_vertices(graph) == 1 + Enum.count(children)
      assert Graph.no_edges(graph) == Enum.count(children)
      assert Graph.out_neighbours(graph, parent.id) ||| Enum.map(children, & &1.id)
    end
  end

  describe "ancestor_ids/1" do
    test "returns a list of ancestor ids" do
      d1 = insert(:domain)
      d2 = insert(:domain, parent_id: d1.id)
      d3 = insert(:domain, parent_id: d2.id)
      d4 = insert(:domain, parent_id: d3.id)

      ids = Tree.ancestor_ids(d4.id)
      assert ids == [d4.id, d3.id, d2.id, d1.id]
    end
  end

  describe "descendent_ids/1" do
    test "returns a list of descendent ids", %{parent: %{id: parent_id}, children: children} do
      child_ids = Enum.map(children, & &1.id)
      ids = Tree.descendent_ids(parent_id)
      assert ids ||| [parent_id | child_ids]
    end
  end
end
