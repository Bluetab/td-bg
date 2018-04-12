defmodule TdBg.TaxonomyErrorsTest do
  use Cabbage.Feature, async: false, file: "taxonomy_errors.feature"
  use TdBgWeb.FeatureCase
  import TdBgWeb.ResponseCode
  import TdBgWeb.Taxonomy
  import TdBgWeb.Authentication, only: :functions
  import TdBgWeb.BusinessConcept
  alias Poison, as: JSON
  alias TdBgWeb.ApiServices.MockTdAuthService
  alias TdBg.BusinessConcepts.BusinessConcept

  @fixed_values %{"Type" => "type",
    "Name" => "name",
    "Description" => "description",
    "Status" => "status",
    "Last Modification" => "last_change_at",
    "Last User" => "last_change_by",
    "Version" => "version",
    "Reject Reason" => "reject_reason",
    "Modification Comments" => "mod_comments",
    "Related To" => "related_to"
  }

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  defand ~r/^an existing Domain Group called "(?<domain_group_name>[^"]+)"$/,
         %{domain_group_name: name}, state do

    token_admin = build_user_token("app-admin", is_admin: true)
    state = Map.merge(state, %{token_admin: token_admin})
    {:ok, status_code, _json_resp} = domain_group_create(token_admin,  %{name: name})
    assert rc_created() == to_response_code(status_code)
    {:ok, state}
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to create a Data Domain as child of Domain Group "(?<domain_group_name>[^"]+)" with following data:$/,
    %{user_name: user_name, domain_group_name: domain_group_name, table: [%{name: name, description: description}]}, state do

    parent = get_domain_group_by_name(state[:token_admin], domain_group_name)
    assert parent["name"] == domain_group_name
    token = build_user_token(user_name)
    {_, status_code, json_resp} = data_domain_create(token, %{name: name, description: description, domain_group_id: parent["id"]})
    {:ok, Map.merge(state, %{status_code: status_code, json_resp: json_resp})}
  end

  defthen ~r/^the system returns a result with code "(?<status_code>[^"]+)"$/,
    %{status_code: status_code}, %{status_code: http_status_code} = state do
    assert status_code == to_response_code(http_status_code)
    {:ok, Map.merge(state, %{})}
  end

  defand ~r/^the system returns a response with following data:$/,
    %{doc_string: json_string}, state do
    # Your implementation here
    actual_data = state[:json_resp]
    expected_data = json_string |> JSON.decode!
    assert JSONDiff.diff(actual_data, expected_data) == []
  end

  defand ~r/^an existing Data Domain called "(?<data_domain_name>[^"]+)" child of "(?<domain_group_name>[^"]+)"$/,
    %{data_domain_name: data_domain_name, domain_group_name: domain_group_name}, state do
    token_admin = build_user_token("app-admin", is_admin: true)
    domain_group = get_domain_group_by_name(token_admin, domain_group_name)
    assert domain_group && domain_group["id"]
    {_, _status_code, json_resp} = data_domain_create(token_admin, %{name: data_domain_name, description: "", domain_group_id: domain_group["id"]})
    data_domain = json_resp["data"]
    assert data_domain["domain_group_id"] == domain_group["id"]

    state = Map.merge(state, %{token_admin: token_admin})
    {:ok, state}
  end

  defwhen ~r/^user "(?<username>[^"]+)" tries to update a Data Domain called "(?<data_domain_name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)" with following data:$/,
    %{username: username, data_domain_name: data_domain_name, domain_group_name: domain_group_name, table: [%{name: name, description: description}]}, state do
    token_admin = build_user_token(username, is_admin: true)
    domain_group = get_domain_group_by_name(token_admin, domain_group_name)
    data_domain = get_data_domain_by_name_and_parent(token_admin, data_domain_name, domain_group["id"])
    {_, status_code, json_resp} = data_domain_update(token_admin, data_domain["id"], %{name: name, description: description})
    {:ok, Map.merge(state, %{token_admin: token_admin, status_code: status_code, json_resp: json_resp})}
  end

  defwhen ~r/^user "(?<username>[^"]+)" tries to create a Domain Group with following data:$/,
    %{username: username, table: [%{name: name, description: description}]},
    state do
    token_admin = build_user_token(username, is_admin: true)
    {_, status_code, json_resp} = domain_group_create(token_admin, %{name: name, description: description})
    {:ok, Map.merge(state, %{token_admin: token_admin, status_code: status_code, json_resp: json_resp})}
  end

  defand ~r/^an existing Domain Group called "(?<child_domain_group_name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)"$/,
         %{child_domain_group_name: child_domain_group_name, domain_group_name: domain_group_name}, %{token_admin: token_admin} = _state do

    parent = get_domain_group_by_name(token_admin, domain_group_name)
    {_, _status_code, _json_resp} = domain_group_create(token_admin,  %{name: child_domain_group_name, parent_id: parent["id"]})
  end

  defand ~r/^an existing Business Concept type called "(?<business_concept_type>[^"]+)" with empty definition$/,
    %{business_concept_type: business_concept_type}, state do
    add_to_business_concept_schema(business_concept_type, [])
    {:ok, Map.merge(state, %{bc_type: business_concept_type})}
  end

  defand ~r/^an existing Business Concept of type "(?<business_concept_type>[^"]+)" in the Data Domain "(?<data_domain_name>[^"]+)" with following data:$/,
    %{business_concept_type: _business_concept_type, data_domain_name: data_domain_name,  table: fields},
    %{token_admin: token_admin} = state do
    attrs = field_value_to_api_attrs(fields, token_admin, @fixed_values)
    data_domain = get_data_domain_by_name(token_admin, data_domain_name)
    business_concept_create(token_admin, data_domain["id"], attrs)
    {:ok, state}
  end

  defand ~r/^"(?<user_name>[^"]+)" tries to create a business concept in the Data Domain "(?<data_domain_name>[^"]+)" with following data:$/,
         %{user_name: user_name, data_domain_name: data_domain_name, table: fields},
         %{token_admin: token_admin} = state do

    token = get_user_token(user_name)
    attrs = field_value_to_api_attrs(fields, token_admin, @fixed_values)
    data_domain = get_data_domain_by_name(token_admin, data_domain_name)

    {_, status_code, json_resp} = business_concept_create(token, data_domain["id"], attrs)
    {:ok, Map.merge(state, %{status_code: status_code, json_resp: json_resp})}

  end

  defwhen ~r/^"(?<user_name>[^"]+)" tries to modify a business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" with following data:$/,
          %{user_name: user_name, business_concept_name: business_concept_name, business_concept_type: business_concept_type, table: fields},
          %{token_admin: token_admin} = state do
    token = get_user_token(user_name)
    business_concept = business_concept_by_name(token_admin, business_concept_name)
    {_, _, %{"data" => current_business_concept}} = business_concept_show(token, business_concept["id"])
    business_concept_id = current_business_concept["id"]
    assert business_concept_type == current_business_concept["type"]
    attrs = field_value_to_api_attrs(fields, token_admin, @fixed_values)
    status = current_business_concept["status"]
    {:ok, status_code, json_resp} = if status == BusinessConcept.status.published do
      business_concept_version_create(token, business_concept_id,  attrs)
    else
      business_concept_update(token, business_concept_id,  attrs)
    end
    {:ok, Map.merge(state, %{status_code: status_code, json_resp: json_resp})}
  end



  defp field_value_to_api_attrs(table, token, fixed_values) do
    table
    |> Enum.reduce(%{}, fn(x, acc) -> Map.put(acc, Map.get(fixed_values, x."Field", x."Field"), x."Value") end)
    |> Map.split(Map.values(fixed_values))
    |> fn({f, v}) -> Map.put(f, "content", v) end.()
    |> load_related_to_ids(token)
  end

  defp load_related_to_ids(attrs, token) do
    related_to = case Map.has_key?(attrs, "related_to") do
      true -> Map.get(attrs, "related_to")
      _ -> ""
    end

    case related_to do
      "" -> attrs
      _ ->
        related_to_ids = related_to
                         |> String.split(",")
                         |> Enum.map(&(business_concept_by_name(token, String.trim(&1))["id"]))
        Map.put(attrs, "related_to", related_to_ids)
    end
  end

end
