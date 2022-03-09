defmodule TdBg.BusinessConcepts.Search.FiltersTest do
  use TdBg.DataCase

  alias TdBg.BusinessConcepts.Search.Aggregations
  alias TdBg.BusinessConcepts.Search.Filters

  setup :create_template

  describe "build_filters/1" do
    test "returns filter corresponding to aggregation terms" do
      aggs = Aggregations.aggregations()

      assert Filters.build_filters(%{"rule_count" => ["rule_terms"]}, aggs) ==
               [%{range: %{"rule_count" => %{gt: 0}}}]

      assert Filters.build_filters(%{"link_count" => ["not_linked_terms"]}, aggs) ==
               [%{range: %{"link_count" => %{lte: 0}}}]

      assert Filters.build_filters(%{"taxonomy" => [1, 2]}, aggs) == [
               %{terms: %{"domain_ids" => [1, 2]}}
             ]

      assert Filters.build_filters(%{"foo" => [1, 2]}, aggs) == [
               %{
                 nested: %{
                   path: "content.foo",
                   query: %{terms: %{"content.foo.external_id.raw" => [1, 2]}}
                 }
               }
             ]

      assert Filters.build_filters(%{"bar" => [1, 2]}, aggs) == [%{terms: %{"bar" => [1, 2]}}]
    end
  end

  defp create_template(_) do
    Templates.create_template(%{
      id: 0,
      name: "onefield",
      content: [
        %{
          "name" => "group",
          "fields" => [
            %{name: "foo", type: "domain", cardinality: "?"}
          ]
        }
      ],
      label: "label",
      scope: "bg"
    })

    :ok
  end
end
