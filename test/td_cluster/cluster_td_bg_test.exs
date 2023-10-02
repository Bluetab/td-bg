defmodule TdCluster.ClusterTdBgTest do
  use ExUnit.Case
  use TdBg.DataCase

  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdCluster.Cluster

  @moduletag sandbox: :shared

  describe "test Cluster.TdBg functions" do
    test "list_business_concept_versions/0" do
      %{id: id} = insert(:business_concept_version)

      assert {:ok, [%BusinessConceptVersion{id: ^id}]} =
               Cluster.TdBg.list_business_concept_versions([])
    end
  end
end
