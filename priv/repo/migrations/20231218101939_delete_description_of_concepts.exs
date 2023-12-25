defmodule TdBg.Repo.Migrations.DeleteDescriptionOfConcepts do
  use Ecto.Migration

  import Ecto.Query
  alias TdBg.Repo

  def up do
    alter table(:business_concept_versions) do
      remove(:description)
    end
  end

  def down do
    alter table(:business_concept_versions) do
      add(:description, :map)
    end

    flush()

    from(t in "business_concept_versions", select: [:id, :content])
    |> Repo.all()
    |> Enum.map(fn %{id: id, content: %{"df_description" => df_description}} ->
      do_update(id, df_description)
    end)
  end

  defp do_update(id, description) do
    from(t in "business_concept_versions")
    |> where([t], t.id == ^id)
    |> update([t], set: [description: ^description])
    |> Repo.update_all([])
  end
end
