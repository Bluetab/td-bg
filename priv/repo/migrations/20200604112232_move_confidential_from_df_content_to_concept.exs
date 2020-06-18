defmodule TdBg.Repo.Migrations.MoveConfidentialFromDfContentToConcept do
  use Ecto.Migration

  import Ecto.Query

  alias TdBg.Repo

  def up do
    concepts =
      from(bcv in "business_concept_versions")
      |> join(:inner, [bcv, c], c in "business_concepts", on: bcv.business_concept_id == c.id)
      |> select([bcv, c], %{concept_id: c.id, bcv_id: bcv.id, content: bcv.content})
      |> Repo.all()
      |> Enum.filter(&with_confidential/1)
      |> Enum.map(&delete_confidential/1)
      |> Enum.map(&update_content/1)
      |> Enum.map(&update_concept_confidential/1)
  end

  def down do
  end

  defp with_confidential(%{content: content}) when content == %{}, do: false

  defp with_confidential(%{content: nil}), do: false

  defp with_confidential(%{content: content}) do
    case Map.get(content, "_confidential") do
      "Si" -> true
      "No" -> true
      _other -> false
    end
  end

  defp delete_confidential(%{content: content} = params) do
    confidential_value = Map.get(content, "_confidential")

    params
    |> Map.put(:content, Map.drop(content, ["_confidential"]))
    |> Map.put(:confidential_value, confidential_value)
  end

  defp update_content(%{bcv_id: id, content: content} = params) do
    from(bcv in "business_concept_versions")
    |> update([bcv], set: [content: ^content])
    |> where([bcv], bcv.id == ^id)
    |> Repo.update_all([])

    params
  end

  defp update_concept_confidential(%{concept_id: id, confidential_value: confidential_value}) do
    confidential =
      case confidential_value do
        "Si" -> true
        _ -> false
      end

    from(c in "business_concepts")
    |> update([c], set: [confidential: ^confidential])
    |> where([c], c.id == ^id)
    |> Repo.update_all([])
  end
end
