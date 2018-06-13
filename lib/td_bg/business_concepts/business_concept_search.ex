defmodule TdBg.BusinessConcept.Search do
  @moduledoc """
    Helper module to construct business concept search queries.
  """
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.Permissions

  @search_service Application.get_env(:td_bg, :elasticsearch)[:search_service]

  def search_business_concept_versions(params, user, page \\ 0, size \\ 50) do
    query = create_query(params, user)
    search = %{from: page * size, size: size, query: query}

    @search_service.search("business_concept", search)
    |> Enum.map(&Map.get(&1, "_source"))
  end

  defp create_query(%{"q" => q}, %{is_admin: true}) do
    %{simple_query_string: %{query: q}}
    |> bool_query
  end

  defp create_query(%{"q" => q}, user) do
    filter = user |> create_filter_clause

    %{simple_query_string: %{query: q}}
    |> bool_query(filter)
  end

  defp create_query(_params, %{is_admin: true}) do
    %{match_all: %{}}
    |> bool_query
  end

  defp create_query(_params, user) do
    filter = create_filter_clause(user)

    %{match_all: %{}}
    |> bool_query(filter)
  end

  defp bool_query(query, filter) do
    %{bool: %{must: query, filter: filter}}
  end

  defp bool_query(query) do
    %{bool: %{must: query}}
  end

  defp create_filter_clause(%{id: id}) do
    should_clause =
      %{user_id: id}
      |> Permissions.get_domain_permissions()
      |> Enum.map(&entry_to_filter_clause(&1))

    %{bool: %{should: should_clause}}
  end

  defp entry_to_filter_clause(%{resource_id: resource_id, permissions: permissions}) do
    domain_clause = %{term: %{domain_ids: resource_id}}

    status_clause =
      permissions
      |> Enum.map(&Map.get(BusinessConcept.permissions_to_status(), &1.name))
      |> Enum.filter(&(!is_nil(&1)))

    %{bool: %{must: [domain_clause, %{terms: %{status: status_clause}}]}}
  end
end
