defmodule TdBg.XLSX.Download do
  @moduledoc """
  Module for processing XLSX file downloads
  """
  alias Elixlsx.Sheet
  alias Elixlsx.Workbook
  alias TdBg.BusinessConcept.Search
  alias TdBg.BusinessConcepts.Links

  @concept_headers ~w(id current_version_id concept_name concept_type domain_external_id domain_name)
  @structure_headers ~w(structure_external_id structure_name structure_system path link_type)

  def links(claims, search_params, opts \\ []) do
    opts = Keyword.put(opts, :target_type, "data_structure")

    claims
    |> Search.stream_all(search_params)
    |> Stream.flat_map(&parse_chunk(&1, claims, opts))
    |> Enum.to_list()
    |> create_workbook()
    |> write_to_memory()
  end

  defp parse_chunk(concepts, claims, opts) do
    Stream.flat_map(concepts, fn concept ->
      concept
      |> fetch_links(claims, opts)
      |> document_content(concept)
    end)
  end

  defp fetch_links(%{"link_count" => 0}, _claims, _opts), do: []

  defp fetch_links(
         %{"business_concept_id" => concept_id, "link_count" => link_count},
         claims,
         opts
       )
       when link_count > 0 do
    concept_id
    |> Links.get_links(opts)
    |> Enum.filter(&Links.has_permissions?(claims, &1))
  end

  defp document_content([], concept) do
    [concept_columns(concept)]
  end

  defp document_content([_ | _] = links, concept) do
    concept_columns = concept_columns(concept)
    Enum.map(links, fn link -> concept_columns ++ structure_columns(link) end)
  end

  defp concept_columns(concept) do
    [
      concept["business_concept_id"],
      concept["id"],
      concept["name"],
      get_in(concept, ["template", "name"]),
      concept["domain"]["external_id"],
      concept["domain"]["name"]
    ]
  end

  defp structure_columns(link) do
    [
      Map.get(link, :external_id),
      Map.get(link, :name),
      get_in(link, [:system, :external_id]),
      Enum.join(Map.get(link, :path, []), " > "),
      extract_link_type(link)
    ]
  end

  defp extract_link_type(%{tags: [tag | _]}) when is_binary(tag), do: tag

  defp extract_link_type(%{tags: tags}) when is_list(tags) and length(tags) > 0 do
    List.first(tags) || ""
  end

  defp extract_link_type(_link), do: ""

  defp create_workbook(rows) do
    %Workbook{
      sheets: [
        %Sheet{name: "links_to_structures", rows: [@concept_headers ++ @structure_headers | rows]}
      ]
    }
  end

  defp write_to_memory(%Workbook{} = workbook) do
    Elixlsx.write_to_memory(workbook, "concept_links.xlsx")
  end
end
