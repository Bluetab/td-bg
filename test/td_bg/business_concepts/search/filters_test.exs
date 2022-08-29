defmodule TdBg.BusinessConcepts.Search.FiltersTest do
  use TdBg.DataCase

  alias TdBg.BusinessConcepts.Search.Aggregations
  alias TdBg.BusinessConcepts.Search.Filters

  setup :create_template

  describe "build_filters/2" do
    test "returns filter corresponding to aggregation terms" do
      aggs = Aggregations.aggregations()

      assert Filters.build_filters(%{"foo" => [1, 2]}, aggs) == [
               %{terms: %{"content.foo" => [1, 2]}}
             ]

      assert Filters.build_filters(%{"bar" => [1, 2]}, aggs) == [%{terms: %{"bar" => [1, 2]}}]
    end

    test "includes domain children in taxonomy filter" do
      %{id: parent_id} = CacheHelpers.insert_domain()
      %{id: domain_id} = CacheHelpers.insert_domain(parent_id: parent_id)

      aggs = Aggregations.aggregations()

      assert Filters.build_filters(%{"taxonomy" => [parent_id]}, aggs) == [
               %{terms: %{"domain_ids" => [parent_id, domain_id]}}
             ]
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
