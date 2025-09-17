defmodule TdBg.BusinessConcepts.RecordEmbeddingsTest do
  use TdBg.DataCase

  import Mox

  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.BusinessConcepts.BusinessConceptVersions.RecordEmbedding
  alias TdBg.BusinessConcepts.BusinessConceptVersions.Workers.EmbeddingsUpsertBatch
  alias TdBg.BusinessConcepts.RecordEmbeddings
  alias TdCluster.TestHelpers.TdAiMock.Embeddings
  alias TdCluster.TestHelpers.TdAiMock.Indices
  alias TdCore.Search.IndexWorkerMock

  describe "upsert_from_concepts_async/1" do
    test "inserts batches of structure ids with embeddings to upsert" do
      stub(MockClusterHandler, :call, fn :ai, TdAi.Indices, :exists_enabled?, [] ->
        {:ok, true}
      end)

      ids = Enum.map(0..1_279, fn i -> i end)
      assert {:ok, jobs} = RecordEmbeddings.upsert_from_concepts_async(ids)

      assert Enum.count(jobs) == 10

      assert jobs = all_enqueued(worker: EmbeddingsUpsertBatch) |> Enum.sort_by(& &1.id)

      for chunk_id <- 0..9 do
        assert %Oban.Job{
                 args: %{"ids" => ids},
                 inserted_at: inserted_at,
                 scheduled_at: scheduled_at
               } =
                 Enum.at(jobs, chunk_id)

        assert DateTime.compare(inserted_at, scheduled_at) == :eq
        init = chunk_id * 128
        ending = (chunk_id + 1) * 128
        expected = init..(ending - 1) |> Enum.to_list()
        assert Enum.sort(ids) == Enum.sort(expected)
      end
    end

    test "schedules the job for future execution if a time is specified" do
      stub(MockClusterHandler, :call, fn :ai, TdAi.Indices, :exists_enabled?, [] ->
        {:ok, true}
      end)

      ids = [1]

      assert {:ok, [%Oban.Job{}]} =
               RecordEmbeddings.upsert_from_concepts_async(ids,
                 schedule_in: 60 * 60
               )

      assert [%Oban.Job{inserted_at: inserted_at, scheduled_at: scheduled_at}] =
               all_enqueued(worker: EmbeddingsUpsertBatch)

      inserted_at = DateTime.truncate(inserted_at, :second)
      scheduled_at = DateTime.truncate(scheduled_at, :second)

      assert DateTime.compare(DateTime.add(inserted_at, 1, :hour), scheduled_at) == :eq
    end

    test "returns noop when there are not indices enabled" do
      stub(MockClusterHandler, :call, fn :ai, TdAi.Indices, :exists_enabled?, [] ->
        {:ok, false}
      end)

      assert :noop == RecordEmbeddings.upsert_from_concepts_async([1])
      assert [] == all_enqueued(worker: EmbeddingsUpsertBatch)
    end
  end

  describe "upsert_from_concepts/1" do
    setup do
      IndexWorkerMock.clear()
      on_exit(fn -> IndexWorkerMock.clear() end)
      :ok
    end

    test "inserts a list for record embeddings" do
      versions = insert_list(5, :business_concept_version)
      ids = Enum.map(versions, & &1.business_concept_id)
      vectors = Enum.map(1..5, fn _ -> [54.0, 10.2, -2.0] end)

      Indices.exists_enabled?(&Mox.expect/4, {:ok, true})

      Embeddings.list(
        &Mox.expect/4,
        Enum.map(versions, fn %{name: name, business_concept: %{type: type, domain: domain}} ->
          "#{name} #{type} #{domain.external_id}"
        end),
        {:ok, %{"default" => vectors, "other" => vectors}}
      )

      assert {10, nil} == RecordEmbeddings.upsert_from_concepts(ids)
      assert record_embeddings = Repo.all(RecordEmbedding)
      assert Enum.count(record_embeddings) == 10

      for %{id: id} <- versions do
        version_embeddings =
          Enum.filter(record_embeddings, &(&1.business_concept_version_id == id))

        assert Enum.count(version_embeddings) == 2
        default_embedding = Enum.find(version_embeddings, &(&1.collection == "default"))
        assert default_embedding.embedding == [54.0, 10.2, -2.0]
        assert default_embedding.dims == 3

        other_embedding = Enum.find(version_embeddings, &(&1.collection == "other"))
        assert other_embedding.embedding == [54.0, 10.2, -2.0]
        assert other_embedding.dims == 3
      end

      assert [{:put_embeddings, :concepts, embeddings_for_concept_ids}] =
               IndexWorkerMock.calls()

      assert embeddings_for_concept_ids == ids
    end

    test "upserts a record embedding on conflict" do
      %{business_concept_version: business_concept_version} =
        insert(:record_embedding, embedding: [-1, 1], dims: 2, collection: "default")

      Indices.exists_enabled?(&Mox.expect/4, {:ok, true})

      Embeddings.list(
        &Mox.expect/4,
        [
          "#{business_concept_version.name} #{business_concept_version.business_concept.type} #{business_concept_version.business_concept.domain.external_id}"
        ],
        {:ok, %{"default" => [[-2.0, 2.0, 3.0]]}}
      )

      assert {1, nil} ==
               RecordEmbeddings.upsert_from_concepts([
                 business_concept_version.business_concept_id
               ])

      assert [record_embedding] = Repo.all(RecordEmbedding)
      assert record_embedding.collection == "default"
      assert record_embedding.embedding == [-2.0, 2.0, 3.0]
      assert record_embedding.dims == 3

      assert [{:put_embeddings, :concepts, embeddings_for_concept_ids}] =
               IndexWorkerMock.calls()

      assert embeddings_for_concept_ids == [business_concept_version.business_concept_id]
    end

    test "returns 0 upserted records if concepts are not found" do
      Indices.exists_enabled?(&Mox.expect/4, {:ok, true})
      assert {0, nil} = RecordEmbeddings.upsert_from_concepts([1])
    end

    test "returns noop when there aren't any indices enabled" do
      Indices.exists_enabled?(&Mox.expect/4, {:ok, false})

      assert :noop == RecordEmbeddings.upsert_from_concepts([1])
    end
  end

  describe "upsert_outdated_async/1" do
    test "inserts jobs to upsert outdated concept record embeddings" do
      Indices.list_indices(
        &Mox.expect/4,
        [enabled: true],
        {:ok, [%{collection_name: "default"}, %{collection_name: "other"}]}
      )

      Indices.exists_enabled?(&Mox.expect/4, {:ok, true})

      bcv_without_embedding = insert(:business_concept_version)
      %{business_concept_version: updated_bcv} = insert(:record_embedding, collection: "default")
      insert(:record_embedding, collection: "other", business_concept_version: updated_bcv)

      %{business_concept_version: outdated_bcv} =
        insert(:record_embedding,
          updated_at: DateTime.add(DateTime.utc_now(), -1, :day),
          collection: "default"
        )

      insert(:record_embedding,
        updated_at: DateTime.add(DateTime.utc_now(), -1, :day),
        collection: "other",
        business_concept_version: outdated_bcv
      )

      %{business_concept_version: missing_other} = insert(:record_embedding)

      assert {:ok, jobs} = RecordEmbeddings.upsert_outdated_async()
      assert Enum.count(jobs) == 1
      assert [job] = all_enqueued(worker: EmbeddingsUpsertBatch)

      assert MapSet.equal?(
               MapSet.new(job.args["ids"]),
               MapSet.new([
                 outdated_bcv.business_concept_id,
                 bcv_without_embedding.business_concept_id,
                 missing_other.business_concept_id
               ])
             )
    end

    test "returns noop when there are no indices enabled" do
      Indices.list_indices(&Mox.expect/4, [enabled: true], {:ok, []})
      assert :noop == RecordEmbeddings.upsert_outdated_async()
    end
  end

  describe "delete_stale_record_embeddings" do
    test "deletes record embeddings that are not in enabled indices" do
      record_embedding_to_delete =
        %{business_concept_version: business_concept_version} =
        insert(:record_embedding, collection: "other")

      record_embedding_to_keep = insert(:record_embedding)

      Indices.list_indices(
        &Mox.expect/4,
        [enabled: true],
        {:ok, [%{collection_name: "default"}]}
      )

      assert {1, [disabled_index]} =
               RecordEmbeddings.delete_stale_record_embeddings()

      assert disabled_index.id == record_embedding_to_delete.id

      assert [record_embedding] = Repo.all(RecordEmbedding)
      assert record_embedding.id == record_embedding_to_keep.id

      assert Repo.get!(BusinessConceptVersion, business_concept_version.id)
    end

    test "deletes all records if there are not enabled indices" do
      Indices.list_indices(&Mox.expect/4, [enabled: true], {:ok, []})

      record_embedding = insert(:record_embedding)
      assert {1, nil} = RecordEmbeddings.delete_stale_record_embeddings()
      assert [] == Repo.all(RecordEmbedding)
      assert [business_concept_version] = Repo.all(BusinessConceptVersion)
      assert business_concept_version.id == record_embedding.business_concept_version_id
    end
  end
end
