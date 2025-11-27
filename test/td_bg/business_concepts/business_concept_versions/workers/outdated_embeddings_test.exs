defmodule TdBg.BusinessConcepts.BusinessConceptVersion.Workers.OutdatedEmbeddingsTest do
  use TdBg.DataCase

  alias TdBg.BusinessConcepts.BusinessConceptVersions.Workers.EmbeddingsUpsertBatch
  alias TdBg.BusinessConcepts.BusinessConceptVersions.Workers.OutdatedEmbeddings
  alias TdCluster.TestHelpers.TdAiMock.Indices

  describe "OutdatedEmbeddings.perform/1" do
    test "inserts a batch of workers" do
      %{business_concept_version: business_concept_version} =
        insert(:record_embedding, updated_at: DateTime.add(DateTime.utc_now(), -1, :day))

      Indices.list_indices(&Mox.expect/4, [enabled: true], {:ok, [%{collection_name: "default"}]})
      Indices.exists_enabled?(&Mox.expect/4, [index_type: "suggestions"], {:ok, true})

      assert :ok == perform_job(OutdatedEmbeddings, %{})
      assert [%Oban.Job{args: %{"ids" => ids}}] = all_enqueued(worker: EmbeddingsUpsertBatch)

      assert ids == [business_concept_version.business_concept_id]
    end

    test "cancels job when indices are not enabled" do
      Indices.list_indices(&Mox.expect/4, [enabled: true], {:ok, []})
      assert {:cancel, :indices_disabled} == perform_job(OutdatedEmbeddings, %{})
    end
  end
end
