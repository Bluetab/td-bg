defmodule TdBg.Repo.Migrations.ModifyCurrentVersion do
  use Ecto.Migration
  import Ecto.Query
  alias TdBg.Repo

  def change do
    updatable_concepts = 
      from(bcv in "business_concept_versions")
      |> where([bcv], bcv.current == true)
      |> where([bcv], bcv.status not in ["published", "deprecated"])
      |> group_by([bcv], bcv.business_concept_id)
      |> select([bcv], bcv.business_concept_id)

    from(bcv in "business_concept_versions")
    |> where([bcv], bcv.business_concept_id in subquery(updatable_concepts))
    |> select([bcv], %{id: bcv.id, status: bcv.status, current: bcv.current, business_concept_id: bcv.business_concept_id, version: bcv.version})
    |> Repo.all()
    |> Enum.group_by(&Map.get(&1, :business_concept_id))
    |> Enum.filter(fn {_b_id, versions} -> Enum.count(versions) > 1 end)
    |> Enum.map(fn {_b_id, versions} -> Enum.sort_by(versions, &Map.get(&1, :version), :desc) end)
    |> Enum.map(&assign_current/1)
  end

  defp assign_current([last_version | versions]) do
    case last_version.current do
      true -> 
        current = Enum.find(versions, &Map.get(&1, :status) == "published")
        update_current(last_version, false)
        update_current(current, true)
    end
  end

  defp update_current(version, current) do
    updated_at = DateTime.utc_now()
    id = Map.get(version, :id)

    from(bcv in "business_concept_versions")
    |> where([bcv], bcv.id == ^id)
    |> update(set: [current: ^current, updated_at: ^updated_at])
    |> Repo.update_all([])
  end
end
