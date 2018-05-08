defmodule TdBg.Repo.Migrations.AddBusinessConceptVersionCurrent do
  use Ecto.Migration
  import Ecto.Query
  alias TdBg.Repo

  def up do
    alter table(:business_concept_versions) do
      add :current, :boolean, default: true, null: true
    end

    flush()

    query = from(v in "business_concept_versions", select: %{business_concept_id: v.business_concept_id, version: max(v.version)}, group_by: v.business_concept_id)
    current_versions = from(v in "business_concept_versions", join: s in subquery(query), on: s.business_concept_id == v.business_concept_id, select: v.id, where: v.version == s.version)
    |> Repo.all

    case current_versions do
      [] -> nil
      _ ->
        from(v in "business_concept_versions", update: [set: [current: true]], where: v.id in ^current_versions)
        |> Repo.update_all([])

        from(v in "business_concept_versions", update: [set: [current: false]], where: v.id not in ^current_versions)
        |> Repo.update_all([])
    end

    alter table(:business_concept_versions) do
      modify :current, :boolean, default: true, null: false
    end

  end

  def down do
    alter table(:business_concept_versions) do
      remove :current
    end
  end

end
