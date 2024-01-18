defmodule TdBg.Repo.Migrations.CopyDescriptionToTemplate do
  use Ecto.Migration

  import Ecto.Query
  alias TdBg.Repo

  @description "df_description"

  def down do
    from(t in "business_concept_versions")
    |> select([:id, :content])
    |> Repo.all()
    |> Enum.map(&remove_data/1)
  end

  def up do
    from(t in "business_concept_versions")
    |> select([:id, :content, :description])
    |> Repo.all()
    |> Enum.map(&add_data/1)
  end

  defp add_data(%{id: id, content: content, description: description}) do
    content
    |> Map.put(@description, description)
    |> then(fn content -> do_update(id, content) end)
  end

  defp remove_data(%{id: id, content: content}) do
    content
    |> Map.delete(@description)
    |> then(fn content -> do_update(id, content) end)
  end

  defp do_update(id, content) do
    from(t in "business_concept_versions")
    |> where([t], t.id == ^id)
    |> update([t], set: [content: ^content])
    |> Repo.update_all([])
  end
end
