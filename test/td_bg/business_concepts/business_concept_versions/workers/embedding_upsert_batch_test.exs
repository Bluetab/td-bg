defmodule TdBg.BusinessConcepts.BusinessConceptVersions.Workers.EmbeddingsUpsertBatchTest do
  use TdBg.DataCase

  alias TdBg.BusinessConcepts.BusinessConceptVersions.RecordEmbedding
  alias TdBg.BusinessConcepts.BusinessConceptVersions.Workers.EmbeddingsUpsertBatch
  alias TdCluster.TestHelpers.TdAiMock.Embeddings
  alias TdCluster.TestHelpers.TdAiMock.Indices

  describe "EmbeddingsUpsertBatch.perform/1" do
    test "inserts a batch of record embeddings" do
      business_concept_version = insert(:business_concept_version)

      Indices.exists_enabled?(&Mox.expect/4, {:ok, true})

      Embeddings.list(
        &Mox.expect/4,
        [
          "#{business_concept_version.name} #{business_concept_version.business_concept.type} #{business_concept_version.business_concept.domain.external_id}"
        ],
        {:ok, %{"default" => [[-2.0, 2.0, 3.0]]}}
      )

      assert :ok =
               perform_job(EmbeddingsUpsertBatch, %{
                 ids: [business_concept_version.business_concept_id]
               })

      assert [record_embedding] = Repo.all(RecordEmbedding)
      assert record_embedding.collection == "default"
      assert record_embedding.embedding == [-2.0, 2.0, 3.0]
      assert record_embedding.dims == 3
    end
  end
end
