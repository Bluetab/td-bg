defmodule TdBg.BusinessConcepts.BusinessConceptVersions.Workers.EmbeddingsDeletionTest do
  use TdBg.DataCase

  alias TdBg.BusinessConcepts.BusinessConceptVersions.RecordEmbedding
  alias TdBg.BusinessConcepts.BusinessConceptVersions.Workers.EmbeddingsDeletion
  alias TdCluster.TestHelpers.TdAiMock.Indices

  @index_type "suggestions"

  describe "EmbeddingsDeletion.perform/1" do
    test "deletes stale record deletions" do
      _record_embedding_to_delete = insert(:record_embedding, collection: "other")
      record_embedding_to_keep = insert(:record_embedding)

      Indices.list_indices(
        &Mox.expect/4,
        [enabled: true, index_type: @index_type],
        {:ok, [%{collection_name: "default"}]}
      )

      assert :ok == perform_job(EmbeddingsDeletion, %{})

      assert [record_embedding] = Repo.all(RecordEmbedding)
      assert record_embedding.id == record_embedding_to_keep.id
    end

    test "deletes all record embeddings when there are no indices enabled" do
      insert(:record_embedding)
      Indices.list_indices(&Mox.expect/4, [enabled: true, index_type: @index_type], {:ok, []})
      assert :ok == perform_job(EmbeddingsDeletion, %{})
      assert [] == Repo.all(RecordEmbedding)
    end
  end
end
