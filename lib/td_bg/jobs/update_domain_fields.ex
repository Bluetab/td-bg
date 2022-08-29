defmodule TdBg.Jobs.UpdateDomainFields do
  @moduledoc """
  Runtime migration of domain content fields. Domain fields which are nested
  documents will be replaced by the domain id (or a list of ids if multiple
  nested documents exist).
  """
  import Ecto.Query

  alias Ecto.Multi
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Repo
  alias TdCache.TemplateCache

  require Logger

  def run do
    fields =
      TemplateCache.list_by_scope!("bg")
      |> Enum.flat_map(&domain_fields/1)

    fields
    |> list_concepts()
    |> Enum.reduce(Multi.new(), &update_domain_fields(&2, &1, fields))
    |> Repo.transaction()
    |> maybe_log()
  end

  defp domain_fields(%{content: [_ | _] = content}) do
    Enum.flat_map(content, &domain_fields/1)
  end

  defp domain_fields(%{"fields" => [_ | _] = fields}) do
    Enum.flat_map(fields, &domain_fields/1)
  end

  defp domain_fields(%{"type" => "domain", "name" => name}), do: [name]

  defp domain_fields(_), do: []

  defp maybe_log({:ok, res}) when map_size(res) > 0 do
    Logger.info("Updated domain fields in #{map_size(res)} concepts")
  end

  defp maybe_log({:ok, _}), do: :ok

  defp list_concepts([]), do: []

  defp list_concepts(fields) do
    Enum.map(fields, fn field ->
      BusinessConceptVersion
      |> where(
        [v],
        not is_nil(v.content[^field]["external_id"]) and not is_nil(v.content[^field]["id"])
      )
      |> or_where(
        [v],
        not is_nil(v.content[^field][0]["external_id"]) and not is_nil(v.content[^field][0]["id"])
      )
    end)
    |> Enum.reduce(fn q, acc -> union(acc, ^q) end)
    |> distinct(true)
    |> Repo.all()
  end

  defp update_domain_fields(multi, %{content: content, id: id}, fields) do
    queryable =
      BusinessConceptVersion
      |> where(id: ^id)
      |> select([bcv], bcv.content)

    Multi.update_all(multi, id, queryable, set: [content: map_content(content, fields)])
  end

  defp map_content(content, fields) do
    fields
    |> Enum.filter(&Map.has_key?(content, &1))
    |> Enum.reduce(content, &update_field/2)
  end

  defp update_field(field, content) do
    Map.update!(content, field, &cast/1)
  end

  defp cast(value) when is_list(value), do: Enum.map(value, &cast/1)
  defp cast(%{"id" => id}) when is_integer(id), do: id

  defp cast(%{"id" => id}) when is_binary(id) do
    case Integer.parse(id) do
      {id, ""} -> id
      _ -> id
    end
  end
end
