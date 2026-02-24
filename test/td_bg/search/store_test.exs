defmodule TdBg.Search.StoreTest do
  use TdBg.DataCase

  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.BusinessConcepts.BusinessConceptVersions.Workers.OutdatedEmbeddings
  alias TdBg.Search.Store
  alias TdCluster.TestHelpers.TdAiMock.Indices

  @index_type "suggestions"

  describe "stream/2 embeddings" do
    test "fetches business concept versions with embeddings by ids" do
      Indices.list_indices(
        &Mox.expect/4,
        [enabled: true, index_type: @index_type],
        {:ok, [%{collection_name: "default"}, %{collection_name: "other"}]}
      )

      embedding = insert(:record_embedding)

      other_embedding =
        insert(:record_embedding,
          business_concept_version: embedding.business_concept_version,
          collection: "other"
        )

      second_embedding = insert(:record_embedding)
      deleted_domain = insert(:domain, deleted_at: DateTime.utc_now())
      business_concept = insert(:business_concept, domain: deleted_domain)

      business_concept_version =
        insert(:business_concept_version, business_concept: business_concept)

      deleted_embedding =
        insert(:record_embedding, business_concept_version: business_concept_version)

      version_without_embedding = insert(:business_concept_version)

      ids = [
        embedding.business_concept_version.business_concept_id,
        second_embedding.business_concept_version.business_concept_id,
        deleted_embedding.business_concept_version.business_concept_id,
        version_without_embedding.business_concept_id
      ]

      {:ok, versions} =
        Repo.transaction(fn ->
          BusinessConceptVersion
          |> Store.stream({:embeddings, ids})
          |> Enum.to_list()
        end)

      assert Enum.count(versions) == 2

      assert version = Enum.find(versions, &(&1.id == embedding.business_concept_version.id))

      for embedding <- [embedding, other_embedding] do
        assert result = Enum.find(version.record_embeddings, &(&1.id == embedding.id))
        assert result.dims == embedding.dims
        assert result.embedding == embedding.embedding
        assert result.collection == embedding.collection
      end

      assert version =
               Enum.find(versions, &(&1.id == second_embedding.business_concept_version.id))

      assert [result] = version.record_embeddings
      assert result.dims == second_embedding.dims
      assert result.embedding == second_embedding.embedding
      assert result.collection == second_embedding.collection
    end

    test "returns empty list when we don't have enabled indices" do
      Indices.list_indices(&Mox.expect/4, [enabled: true, index_type: @index_type], {:ok, []})

      assert {:ok, []} ==
               Repo.transaction(fn ->
                 BusinessConceptVersion
                 |> Store.stream({:embeddings, [1]})
                 |> Enum.to_list()
               end)
    end
  end

  describe "run/2 embeddings" do
    test "inserts outdated embeddings worker" do
      assert {:ok, _jobs} = Store.run(BusinessConceptVersion, {:embeddings, :all})
      assert [_job] = all_enqueued(worker: OutdatedEmbeddings)
    end
  end

  describe "fetch/2" do
    setup do
      business_concept_versions =
        insert_list(10, :business_concept_version, status: "draft", version: 0, current: true)

      business_concept = insert(:business_concept)

      published_business_concept_version =
        insert(:business_concept_version,
          business_concept: business_concept,
          status: "published",
          version: 1
        )

      _business_concept_version =
        insert(:business_concept_version,
          business_concept: business_concept,
          status: "draft",
          version: 0
        )

      [
        business_concept_versions: business_concept_versions,
        published_business_concept_version: published_business_concept_version
      ]
    end

    test "fetches current or published business concept versions encoded for Elasticsearch", %{
      business_concept_versions: business_concept_versions,
      published_business_concept_version: published_business_concept_version
    } do
      assert results = Store.fetch(BusinessConceptVersion, :all)
      assert length(results) == 11
      result_ids = Enum.map(results, & &1.id)
      assert published_business_concept_version.id in result_ids

      assert Enum.map(business_concept_versions, & &1.id) ==
               result_ids -- [published_business_concept_version.id]
    end

    test "fetches current or published business concept versions encoded for Elasticsearch by ids",
         %{
           published_business_concept_version: published_business_concept_version
         } do
      assert results =
               Store.fetch(BusinessConceptVersion, [
                 published_business_concept_version.business_concept_id
               ])

      assert length(results) == 1
      assert results |> Enum.map(& &1.id) == [published_business_concept_version.id]
    end
  end
end
