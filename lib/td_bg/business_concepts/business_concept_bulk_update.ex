defmodule TdBg.BusinessConcept.BulkUpdate do
  @moduledoc false
  require Logger

  alias TdBg.BusinessConceptLoader
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Repo
  alias TdBg.Taxonomies

  @df_cache Application.get_env(:td_bg, :df_cache)

  def update_all(user, business_concept_versions, params) do
    business_concept_versions =
      business_concept_versions
      |> ids_from_business_concept_versions()
      |> BusinessConcepts.business_concept_versions_by_ids()

    with {:ok, update_attributes} <-
           update_attributes_from_params(user, params, Enum.at(business_concept_versions, 0)),
           {:ok, bcv_list} <- update(business_concept_versions, update_attributes) do

      bcv_list
      |> Enum.each(&refreshInfo(&1))

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
    end
  end

  defp update_data([head | tail], update_attributes, acc) do
    case BusinessConcepts.update_business_concept_version(head, update_attributes, false) do
      {:ok, bcv} ->
        update_data(tail, update_attributes, [bcv | acc])
      error ->
        error
    end
  end

  defp update_data(_, _, acc), do: {:ok, acc}

  defp refreshInfo(%BusinessConceptVersion{} = business_concept_version) do # TODO: put in utils file
    business_concept_id = business_concept_version.business_concept_id
    BusinessConceptLoader.refresh(business_concept_id)
    params = BusinessConcepts.retrieve_last_bc_version_params(business_concept_id)
    BusinessConcepts.index_business_concept_versions(business_concept_id, params)
  end

  defp ids_from_business_concept_versions(business_concept_versions) do
    Enum.map(business_concept_versions, &Map.get(&1, "id"))
  end

  defp update_attributes_from_params(user, params, business_concept_version) do
    template = get_template(business_concept_version)
    content_schema = Map.get(template, :content)
    domain_id = Map.get(params, "domain_id", nil)

    case domain_id && Taxonomies.get_domain(domain_id) do
      nil ->
        {:error, :missing_domain}

      _ ->
        business_concept_attrs =
          %{}
          |> Map.put("domain_id", domain_id)
          |> Map.put("last_change_by", user.id)
          |> Map.put("last_change_at", DateTime.utc_now())

        update_attributes =
          params
          |> Map.put("business_concept", business_concept_attrs)
          |> Map.put("content_schema", content_schema)
          |> Map.update("content", %{}, & &1)
          |> Map.put("last_change_by", user.id)
          |> Map.put("last_change_at", DateTime.utc_now())

        {:ok, update_attributes}
    end
  end

  defp get_template(%BusinessConceptVersion{} = version) do
    version
    |> Map.get(:business_concept)
    |> Map.get(:type)
    |> @df_cache.get_template_by_name
  end
end
