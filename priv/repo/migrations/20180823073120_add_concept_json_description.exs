defmodule TdBg.Repo.Migrations.AddConceptJsonDescription do
  use Ecto.Migration
  import Ecto.Query
  alias TdBg.Repo

  defp description_to_map(%{id: id, description: text}) do
    t = if text == nil, do: "", else: text

    nodes =
      t
      |> String.split("\n")
      |> Enum.map(fn text ->
        %{object: "block", type: "paragraph", nodes: [%{object: "text", leaves: [%{text: text}]}]}
      end)

    %{id: id, description: %{document: %{nodes: nodes}}}
  end

  defp update_description(%{id: id, description: map}) do
    from(v in "business_concept_versions",
      update: [set: [description: ^map]],
      where: v.id == ^id
    )
    |> Repo.update_all([])
  end

  def up do
    rename(table(:business_concept_versions), :description, to: :description_backup)
    alter(table(:business_concept_versions), do: add(:description, :map))
    flush()

    from(v in "business_concept_versions", select: %{id: v.id, description: v.description_backup})
    |> Repo.all()
    |> Enum.map(&description_to_map/1)
    |> Enum.each(&update_description/1)
  end

  def down do
    alter(table(:business_concept_versions), do: remove(:description))
    rename(table(:business_concept_versions), :description_backup, to: :description)
  end
end
