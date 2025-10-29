defmodule TdBg.BusinessConcept.BulkUpdate do
  @moduledoc false
  require Logger

  alias TdBg.Auth.Claims
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Cache.ConceptLoader
  alias TdBg.Repo
  alias TdBg.Taxonomies
  alias TdDfLib.Format
  alias TdDfLib.Parser

  @default_lang Application.compile_env(:td_cache, :lang)

  def update_all(%Claims{} = claims, business_concept_versions, params) do
    business_concept_versions =
      business_concept_versions
      |> ids_from_business_concept_versions()
      |> BusinessConcepts.business_concept_versions_by_ids()

    with {:ok, update_attributes} <-
           update_attributes_from_params(claims, params, business_concept_versions),
         {:ok, bcv_list} <- update(business_concept_versions, update_attributes) do
      Enum.each(bcv_list, &refresh_cache_and_elastic/1)

      {:ok, bcv_list |> Enum.map(& &1.id)}
    else
      error ->
        error
    end
  end

  defp update(business_concept_versions, update_attributes) do
    Logger.info("Updating business concept versions...")
    start_time = DateTime.utc_now()

    transaction_result =
      Repo.transaction(fn ->
        update_in_transaction(business_concept_versions, update_attributes)
      end)

    end_time = DateTime.utc_now()

    Logger.info(
      "Business concept versions updated. Elapsed seconds: #{DateTime.diff(end_time, start_time)}"
    )

    transaction_result
  end

  defp update_in_transaction(business_concept_versions, update_attributes) do
    case update_data(business_concept_versions, update_attributes, []) do
      {:ok, bcv_list} ->
        bcv_list

      {:error, err} ->
        Repo.rollback(err)

      {:error, _action, err, _} ->
        Repo.rollback(err)
    end
  end

  defp update_data([head | tail], update_attributes, acc) do
    case BusinessConcepts.bulk_update_business_concept_version(head, update_attributes) do
      {:ok, bcv} ->
        update_data(tail, update_attributes, [bcv | acc])

      error ->
        error
    end
  end

  defp update_data(_, _, acc), do: {:ok, acc}

  defp refresh_cache_and_elastic(%BusinessConceptVersion{} = business_concept_version) do
    business_concept_id = business_concept_version.business_concept_id
    ConceptLoader.refresh(business_concept_id)
  end

  defp ids_from_business_concept_versions(business_concept_versions) do
    Enum.map(business_concept_versions, &Map.get(&1, "id"))
  end

  defp update_attributes_from_params(_claims, _params, []) do
    {:error, :empty_business_concepts}
  end

  defp update_attributes_from_params(
         %Claims{user_id: user_id},
         params,
         business_concept_versions
       ) do
    business_concept_version = Enum.at(business_concept_versions, 0)

    case BusinessConcepts.get_template(business_concept_version) do
      nil ->
        {:error, :template_not_found}

      %{content: content} ->
        content_schema = Format.flatten_content_fields(content, @default_lang)
        domain_id = Map.get(params, "domain_id", nil)

        case Taxonomies.get_domain(domain_id) do
          {:ok, _domain} ->
            business_concept_attrs =
              %{}
              |> Map.put("domain_id", domain_id)
              |> Map.put("last_change_by", user_id)
              |> Map.put("last_change_at", DateTime.utc_now())

            update_attributes =
              params
              |> Map.put("business_concept", business_concept_attrs)
              |> Map.put("content_schema", content_schema)
              |> Map.update("content", %{}, &content_fields(&1, content_schema, domain_id))
              |> Map.put("last_change_by", user_id)
              |> Map.put("last_change_at", DateTime.utc_now())

            {:ok, update_attributes}

          _error ->
            {:error, :missing_domain}
        end
    end
  end

  defp content_fields(content, content_schema, domain_id, lang \\ @default_lang)

  defp content_fields(%{} = content, content_schema, domain_id, lang) do
    fields = Map.keys(content)
    content_schema = Enum.filter(content_schema, &(Map.get(&1, "name") in fields))

    Parser.format_content(%{
      content: Enum.reduce(content, Map.new(), &non_empty/2),
      content_schema: content_schema,
      domain_ids: [domain_id],
      lang: lang
    })
  end

  defp content_fields(content, _, _, _), do: content

  defp non_empty({_k, %{"value" => nil}}, acc), do: acc

  defp non_empty({_k, %{"value" => ""}}, acc), do: acc

  defp non_empty({_k, %{"value" => []}}, acc), do: acc

  defp non_empty({_k, %{"value" => value}}, acc) when value == %{}, do: acc

  defp non_empty({key, value}, acc), do: Map.put(acc, key, value)
end
