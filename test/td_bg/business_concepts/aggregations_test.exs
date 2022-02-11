defmodule TdBg.Search.AggregationsTest do
  use TdBg.DataCase

  alias TdBg.Search.Aggregations

  setup _context do
    Templates.create_template(%{
      id: 0,
      name: "onefield",
      content: [
        %{
          "name" => "group",
          "fields" => [
            %{name: "fieldname", type: "string", cardinality: "?", values: %{}},
            %{name: "userfield", type: "user", cardinality: "?", values: %{}},
            %{name: "foo", type: "domain", cardinality: "?"}
          ]
        }
      ],
      label: "label",
      scope: "bg"
    })

    :ok
  end

  describe "aggregation_terms/0" do
    test "returns aggregation terms of type user with size 50" do
      aggs = Aggregations.aggregation_terms()

      %{field: field, size: size} =
        aggs
        |> Map.get("userfield")
        |> Map.get(:terms)
        |> Map.take([:field, :size])

      assert size == 50
      assert field == "content.userfield.raw"
    end
  end

  describe "build_filters/1" do
    import Aggregations, only: [build_filters: 1]

    test "returns filter corresponding to aggregation terms" do
      assert build_filters(%{"rule_count" => ["rule_terms"]}) ==
               [%{range: %{"rule_count" => %{gt: 0}}}]

      assert build_filters(%{"link_count" => ["not_linked_terms"]}) ==
               [%{range: %{"link_count" => %{lte: 0}}}]

      assert build_filters(%{"taxonomy" => [1, 2]}) == [
               %{
                 nested: %{
                   path: "domain_parents",
                   query: %{terms: %{"domain_parents.id" => [1, 2]}}
                 }
               }
             ]

      assert build_filters(%{"foo" => [1, 2]}) == [
               %{
                 nested: %{
                   path: "content.foo",
                   query: %{terms: %{"content.foo.external_id.raw" => [1, 2]}}
                 }
               }
             ]
    end
  end
end
