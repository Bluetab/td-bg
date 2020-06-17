defmodule TdBg.Repo.Migrations.AddBusinessConceptConfidentialField do
  use Ecto.Migration

  import Ecto.Query

  alias TdBg.Repo

  def up do
    alter table(:business_concepts) do
      add(:confidential, :boolean, default: false)
    end
  end

  # Concepts with false value in confidential will miss its previous content value in rollback
  def down do
    confidential_concepts =
      from(bcv in "business_concept_versions")
      |> join(:inner, [bcv, c], c in "business_concepts", on: bcv.business_concept_id == c.id)
      |> select([bcv, c], %{concept_id: c.id, bcv_id: bcv.id, content: bcv.content})
      |> where([_, c], c.confidential == true)
      |> Repo.all()
      |> Enum.map(&add_confidential/1)
      |> Enum.map(&update_content/1)

    alter table(:business_concepts) do
      remove(:confidential)
    end
  end

  defp add_confidential(%{content: content} = params) do
    Map.put(params, :content, Map.put(content, "_confidential", "Si"))
  end

  defp update_content(%{bcv_id: id, content: content} = params) do
    from(bcv in "business_concept_versions")
    |> update([bcv], set: [content: ^content])
    |> where([bcv], bcv.id == ^id)
    |> Repo.update_all([])
  end
end
