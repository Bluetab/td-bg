defmodule TdBg.BusinessConcepts.Search.AggregationsTest do
  use TdBg.DataCase

  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdCore.Search.ElasticDocumentProtocol

  setup do
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

  describe "aggregations/0" do
    test "returns aggregation terms of type user with size 50" do
      aggs = ElasticDocumentProtocol.aggregations(%BusinessConceptVersion{})

      %{field: field, size: size} =
        aggs
        |> Map.get("userfield")
        |> Map.get(:terms)
        |> Map.take([:field, :size])

      assert size == 50
      assert field == "content.userfield.raw"
    end
  end
end
