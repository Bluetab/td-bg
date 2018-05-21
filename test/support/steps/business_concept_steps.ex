defmodule TdBg.BusinessConceptSteps do
  @moduledoc false
  use Cabbage.Feature
  use ExUnit.CaseTemplate
  import TdBgWeb.BusinessConcept
  import TdBgWeb.ResponseCode
  import TdBgWeb.Authentication, only: :functions

  defand ~r/^an existing Business Concept type called "(?<business_concept_type>[^"]+)" with empty definition$/,
    %{business_concept_type: business_concept_type}, state do
      create_template(business_concept_type, [])
      {:ok, Map.merge(state, %{bc_type: business_concept_type})}
  end

  defand ~r/^"(?<user_name>[^"]+)" tries to create a business concept in the Domain "(?<domain_name>[^"]+)" with following data:$/,
    %{user_name: user_name, domain_name: domain_name, table: fields},
    %{token_admin: token_admin} = state do
      token = get_user_token(user_name)
      attrs = field_value_to_api_attrs(fields, token_admin, fixed_values())
      domain = get_domain_by_name(token_admin, domain_name)
      {_, status_code, json_resp} = business_concept_create(token, domain["id"], attrs)
      {:ok, Map.merge(state, %{status_code: status_code, json_resp: json_resp})}

  end

  defand ~r/^"(?<user_name>[^"]+)" is able to view business concept "(?<business_concept_name>[^"]+)" as a child of Domain "(?<domain_name>[^"]+)" with following data:$/,
    %{user_name: user_name, business_concept_name: business_concept_name, domain_name: domain_name, table: fields},
    %{token_admin: token_admin} = state do

      token = get_user_token(user_name)
      domain = get_domain_by_name(token_admin, domain_name)
      business_concept = business_concept_by_name(token, business_concept_name)
      {_, http_status_code, %{"data" => business_concept}} = business_concept_show(token, business_concept["id"])
      assert rc_ok() == to_response_code(http_status_code)
      assert business_concept["name"] == business_concept_name
      assert business_concept["domain"]["id"] == domain["id"]
      attrs = field_value_to_api_attrs(fields, token_admin, fixed_values())
      assert_attrs(attrs, business_concept)
      {:ok, state}
  end

  defand ~r/^an existing Business Concept type called "(?<business_concept_type>[^"]+)" with following definition:$/,
          %{business_concept_type: business_concept_type, table: table},
          %{} = state do
    schema = table
    |> Enum.map(fn(row) ->
      add_all_schema_fields(row)
    end)
    create_template(business_concept_type, schema)
    {:ok, Map.merge(state, %{bc_type: business_concept_type})}
  end

  defand ~r/^an existing Business Concept in the Domain "(?<domain_name>[^"]+)" with following data:$/,
    %{domain_name: domain_name, table: fields}, state do
    token_admin = case state[:token_admin] do
                nil -> build_user_token("app-admin", is_admin: true)
                _ -> state[:token_admin]
              end
    domain = get_domain_by_name(token_admin, domain_name)
    attrs = field_value_to_api_attrs(fields, token_admin, fixed_values())
    business_concept_create(token_admin, domain["id"], attrs)
  end

  defand ~r/^"(?<user_name>[^"]+)" is not able to view business concept "(?<business_concept_name>[^"]+)" as a child of Domain "(?<domain_name>[^"]+)"$/,
    %{user_name: user_name, business_concept_name: business_concept_name, domain_name: domain_name},
    %{token_admin: token_admin} = state do

    token = get_user_token(user_name)
    domain = get_domain_by_name(token_admin, domain_name)
    business_concept = business_concept_by_name(token, business_concept_name)
    {_, http_status_code, %{"data" => business_concept}} = business_concept_show(token, business_concept["id"])
    assert rc_ok() == to_response_code(http_status_code)
    assert business_concept["name"] == business_concept_name
    assert business_concept["domain_id"] !== domain["id"]
    {:ok, state}
  end

  defand ~r/^an existing Business Concept of type "(?<business_concept_type>[^"]+)" in the Domain "(?<domain_name>[^"]+)" with following data:$/,
    %{business_concept_type: _business_concept_type, domain_name: domain_name,  table: fields},
    %{token_admin: token_admin} = state do
      attrs = field_value_to_api_attrs(fields, token_admin, fixed_values())
      domain = get_domain_by_name(token_admin, domain_name)
      business_concept_create(token_admin, domain["id"], attrs)
    {:ok, state}
  end

  defwhen ~r/^"(?<user_name>[^"]+)" tries to modify a business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" with following data:$/,
    %{user_name: user_name, business_concept_name: business_concept_name, business_concept_type: business_concept_type, table: fields},
    %{token_admin: token_admin} = state do
      token = get_user_token(user_name)
      business_concept = business_concept_by_name(token_admin, business_concept_name)
      {_, _, %{"data" => current_business_concept}} = business_concept_show(token, business_concept["id"])
      business_concept_id = current_business_concept["id"]
      assert business_concept_type == current_business_concept["type"]
      attrs = field_value_to_api_attrs(fields, token_admin, fixed_values())
      status = current_business_concept["status"]
      published = BusinessConcept.status.published
      rejected  = BusinessConcept.status.rejected

      case status do
          ^published -> business_concept_version(token, business_concept_id)
          ^rejected -> business_concept_undo_rejection(token, business_concept_id)
          _ -> nil
      end
      {_, status_code, json_resp} = business_concept_update(token, business_concept_id,  attrs)
      {:ok, Map.merge(state, %{status_code: status_code, json_resp: json_resp})}
  end

  defand ~r/^if result (?<result>[^"]+) is "(?<status_code>[^"]+)", user (?<user_name>[^"]+) is able to view business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" with following data:$/,
    %{result: result, status_code: status_code, user_name: user_name, business_concept_name: business_concept_name, business_concept_type: business_concept_type, table: fields},
    %{token_admin: token_admin} = state do

    token = get_user_token(user_name)
    if result == status_code do
      business_concept_tmp = business_concept_by_name(token_admin, business_concept_name)
      assert business_concept_type == business_concept_tmp["type"]
      {_, http_status_code, %{"data" => business_concept}} = business_concept_show(token, business_concept_tmp["id"])
      assert rc_ok() == to_response_code(http_status_code)
      attrs = field_value_to_api_attrs(fields, token_admin, fixed_values())
      assert_attrs(attrs, business_concept)
      {:ok, Map.merge(state, %{business_concept: business_concept})}
    else
      {:ok, state}
    end
  end

 defwhen ~r/^"(?<user_name>[^"]+)" tries to send for approval a business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)"$/,
          %{user_name: user_name, business_concept_name: business_concept_name, business_concept_type: business_concept_type},
          %{token_admin: token_admin} = state do

    token = get_user_token(user_name)
    business_concept = business_concept_by_name_and_type(token_admin, business_concept_name, business_concept_type)
    business_concept_version_id = business_concept["business_concept_version_id"]
    {_, status_code} = business_concept_version_send_for_approval(token, business_concept_version_id)
    {:ok, Map.merge(state, %{status_code: status_code})}
 end

 defand ~r/^the status of business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" is set to "(?<status>[^"]+)"$/,
  %{business_concept_name: business_concept_name, business_concept_type: business_concept_type, status: status},
  %{token_admin: token_admin} = state do
    business_concept = business_concept_by_name_and_type(token_admin, business_concept_name, business_concept_type)
    business_concept_id = business_concept["id"]
    change_business_concept_status(token_admin, business_concept_id, status)
    {:ok, state}
  end

  defwhen ~r/^(?<user_name>[^"]+) tries to publish a business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)"$/,
    %{user_name: user_name, business_concept_name: business_concept_name, business_concept_type: business_concept_type},
    %{token_admin: token_admin} = state do
      token = get_user_token(user_name)
      business_concept = business_concept_by_name_and_type(token_admin, business_concept_name, business_concept_type)
      business_concept_version_id = business_concept["business_concept_version_id"]
      {_, status_code} = business_concept_version_publish(token, business_concept_version_id)
      {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defwhen ~r/^(?<user_name>[^"]+) tries to reject a business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" and reject reason "(?<reject_reason>[^"]+)"$/,
    %{user_name: user_name, business_concept_name: business_concept_name, business_concept_type: business_concept_type, reject_reason: reject_reason},
    %{token_admin: token_admin} = state do
      token = get_user_token(user_name)
      business_concept = business_concept_by_name_and_type(token_admin, business_concept_name, business_concept_type)
      business_concept_version_id = business_concept["business_concept_version_id"]
      {_, status_code} = business_concept_version_reject(token, business_concept_version_id, reject_reason)

      {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defand ~r/^if result (?<result>[^"]+) is "(?<status_code>[^"]+)", user (?<user_name>[^"]+) is able to view business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" and version "(?<version>[^"]+)" with following data:$/,
    %{result: result, status_code: status_code, user_name: user_name, business_concept_name: business_concept_name, business_concept_type: business_concept_type, version: version, table: fields},
    %{token_admin: token_admin} = state do

      token = get_user_token(user_name)
      business_concept_version = String.to_integer(version)

      if result == status_code do
        business_concept_tmp = business_concept_by_version_name_and_type(
                    token_admin, business_concept_version, business_concept_name,
                    business_concept_type)
        assert business_concept_version == business_concept_tmp["version"]
        assert business_concept_type == business_concept_tmp["type"]
        {_, http_status_code, %{"data" => business_concept}} = business_concept_version_show(token, business_concept_tmp["business_concept_version_id"])
        assert rc_ok() == to_response_code(http_status_code)
        attrs = field_value_to_api_attrs(fields, token_admin, fixed_values())
        assert_attrs(attrs, business_concept)
        {:ok, Map.merge(state, %{business_concept: business_concept})}
      else
        {:ok, state}
      end
  end

  defand ~r/^the status of business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" is set to "(?<business_concept_status>[^"]+)" for version (?<version>\d+)$/,
    %{business_concept_name: business_concept_name, business_concept_type: business_concept_type, business_concept_status: business_concept_status, version: version},
    %{token_admin: token_admin} = state do

    business_concept = business_concept_by_name_and_type(token_admin, business_concept_name, business_concept_type)
    business_concept_id = business_concept["id"]
    business_concept_version = String.to_integer(version)
    if business_concept_version > 1 do
      Enum.each(2..business_concept_version, fn(_x) ->
        change_business_concept_status(token_admin, business_concept_id, BusinessConcept.status.published)
        change_business_concept_status(token_admin, business_concept_id, BusinessConcept.status.draft)
      end)
    end
    change_business_concept_status(token_admin, business_concept_id, business_concept_status)

    {:ok, state}
   end

  defand ~r/^business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" has been modified with following data:$/,
  %{business_concept_name: business_concept_name, business_concept_type: business_concept_type, table: fields},
  %{token_admin: token_admin} = state do
    business_concept = business_concept_by_name(token_admin, business_concept_name)
    assert business_concept_type == business_concept["type"]
    attrs = field_value_to_api_attrs(fields, token_admin, fixed_values())
    status = business_concept["status"]

    case status == BusinessConcept.status.published do
      true -> business_concept_version(token_admin, business_concept["id"])
      _ -> nil
    end

    business_concept_update(token_admin, business_concept["id"],  attrs)

    {:ok, state}
  end

  defwhen ~r/^(?<user_name>[^"]+) tries to delete a business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)"$/,
    %{user_name: user_name, business_concept_name: business_concept_name, business_concept_type: business_concept_type},
    %{token_admin: token_admin} = state do

      business_concept_tmp = business_concept_by_name_and_type(
                  token_admin, business_concept_name,
                  business_concept_type)
      assert business_concept_tmp
      token = get_user_token(user_name)
      business_concept_version_id = business_concept_tmp["business_concept_version_id"]
      {_, status_code} = business_concept_version_delete(token, business_concept_version_id)
      {:ok, Map.merge(state, %{status_code: status_code, deleted_business_concept_version_id: business_concept_version_id})}
  end

  defand ~r/^if result (?<result>[^"]+) is "(?<status_code>[^"]+)", user (?<user_name>[^"]+) is not able to view business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)"$/,
    %{result: result, status_code: status_code, user_name: user_name, business_concept_name: _business_concept_name, business_concept_type: _business_concept_type},
    %{deleted_business_concept_version_id: business_concept_version_id} = state do
      if result == status_code do
        token = get_user_token(user_name)
        {_, http_status_code, _} = business_concept_version_show(token, business_concept_version_id)
        assert rc_not_found() == to_response_code(http_status_code)
        {:ok, state}
      else
        {:ok, state}
      end
  end

  defand ~r/^if result (?<result>[^"]+) is not "(?<status_code>[^"]+)", user (?<user_name>[^"]+) is able to view business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" and version "(?<version>[^"]+)" with following data:$/,
    %{result: result, status_code: status_code, user_name: user_name, business_concept_name: business_concept_name, business_concept_type: business_concept_type, version: version, table: fields},
    %{token_admin: token_admin} = state do
      token = get_user_token(user_name)
      business_concept_version = String.to_integer(version)

      if result != status_code do
        business_concept_tmp = business_concept_by_version_name_and_type(
                    token_admin, business_concept_version, business_concept_name,
                    business_concept_type)
        assert business_concept_version == business_concept_tmp["version"]
        assert business_concept_type == business_concept_tmp["type"]
        {_, http_status_code, %{"data" => business_concept}} = business_concept_version_show(token, business_concept_tmp["business_concept_version_id"])
        assert rc_ok() == to_response_code(http_status_code)
        attrs = field_value_to_api_attrs(fields, token_admin, fixed_values())
        assert_attrs(attrs, business_concept)
        {:ok, state}
      else
        {:ok, state}
      end
  end

  defand ~r/^user (?<user_name>[^"]+) is able to view business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" and version "(?<version>[^"]+)" with following data:$/,
    %{user_name: user_name,  business_concept_name: business_concept_name, business_concept_type: business_concept_type, version: version, table: fields},
    %{token_admin: token_admin} = state do
      business_concept_version = String.to_integer(version)
      business_concept_tmp = business_concept_by_version_name_and_type(token_admin,
                                                                      business_concept_version,
                                                                      business_concept_name,
                                                                      business_concept_type)
      assert business_concept_tmp
      assert business_concept_type == business_concept_tmp["type"]
      token = get_user_token(user_name)
      {_, http_status_code, %{"data" => business_concept}} = business_concept_version_show(token, business_concept_tmp["business_concept_version_id"])
      assert rc_ok() == to_response_code(http_status_code)
      attrs = field_value_to_api_attrs(fields, token_admin, fixed_values())
      assert_attrs(attrs, business_concept)
      {:ok, state}
  end

  defand ~r/^if result (?<result>[^"]+) is "(?<status_code>[^"]+)",  business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" and version "(?<version>[^"]+)" does not exist$/,
    %{result: result, status_code: status_code, business_concept_name: business_concept_name, business_concept_type: business_concept_type, version: version},
    %{token_admin: token_admin} = _state do
      if result == status_code do
        business_concept_version = String.to_integer(version)
        business_concept_tmp = business_concept_by_version_name_and_type(token_admin,
                                                                        business_concept_version,
                                                                        business_concept_name,
                                                                        business_concept_type)
        assert !business_concept_tmp
      end
  end

  defwhen ~r/^(?<user_name>[^"]+) tries to deprecate a business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)"$/,
    %{user_name: user_name, business_concept_name: business_concept_name, business_concept_type: business_concept_type},
    %{token_admin: token_admin} = state do

      token = get_user_token(user_name)
      business_concept = business_concept_by_name_and_type(token_admin, business_concept_name, business_concept_type)
      business_concept_version_id = business_concept["business_concept_version_id"]
      {_, status_code} = business_concept_version_deprecate(token, business_concept_version_id)
      {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defwhen ~r/^(?<user_name>[^"]+) tries to query history for a business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)"$/,
    %{user_name: user_name, business_concept_name: business_concept_name, business_concept_type: business_concept_type},
    %{token_admin: token_admin} = state do
      business_concept_version = business_concept_by_name_and_type(token_admin, business_concept_name, business_concept_type)
      business_concept_id = business_concept_version["id"]
      token = get_user_token(user_name)
      {_, status_code, %{"data" => business_concept_versions}} = business_concept_versions(token, business_concept_id)
      assert rc_ok() == to_response_code(status_code)
      {:ok, Map.merge(state, %{business_concept_versions: business_concept_versions})}
  end

  defwhen ~r/^"(?<user_name>[^"]+)" tries to create a new alias "(?<business_concept_alias>[^"]+)" for business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)"$/,
    %{user_name: user_name, business_concept_alias: business_concept_alias, business_concept_name: business_concept_name, business_concept_type: business_concept_type},
    %{token_admin: token_admin} = state do
      business_concept_version = business_concept_by_name_and_type(token_admin, business_concept_name, business_concept_type)
      business_concept_id = business_concept_version["id"]
      token = get_user_token(user_name)
      creation_attrs = %{name: business_concept_alias}
      {_, status_code, _} = business_concept_alias_create(token, business_concept_id, creation_attrs)
      {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defand ~r/^if (?<result>[^"]+) is "(?<status_code>[^"]+)", user (?<user_name>[^"]+) is able to see following list of aliases for business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)"$/,
    %{result: result, status_code: status_code, user_name: user_name, business_concept_name: business_concept_name, business_concept_type: business_concept_type, table: fields},
     %{token_admin: token_admin} = _state do
    if result == status_code do
      assert_visible_aliases(token_admin, business_concept_name, business_concept_type, user_name, fields)
    end
  end

  defand ~r/^business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" has an alias "(?<business_concept_alias>[^"]+)"$/,
    %{business_concept_name: business_concept_name, business_concept_type: business_concept_type, business_concept_alias: business_concept_alias},
     %{token_admin: token_admin} = _state do
      business_concept = business_concept_by_name_and_type(token_admin, business_concept_name, business_concept_type)
      business_concept_id = business_concept["id"]
      creation_attrs = %{name: business_concept_alias}
      {_, status_code, _} = business_concept_alias_create(token_admin, business_concept_id, creation_attrs)
      assert rc_created() == to_response_code(status_code)
  end

  defwhen ~r/^(?<user_name>[^"]+) tries to delete alias "(?<business_concept_alias>[^"]+)" for business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)"$/,
    %{user_name: user_name, business_concept_alias: business_concept_alias, business_concept_name: business_concept_name, business_concept_type: business_concept_type},
    %{token_admin: token_admin} = state do
      business_concept = business_concept_by_name_and_type(token_admin, business_concept_name, business_concept_type)
      business_concept_id = business_concept["id"]
      business_concept_alias = business_concept_alias_by_name(token_admin, business_concept_id, business_concept_alias)
      assert business_concept_alias
      token = get_user_token(user_name)
      {_, status_code} = business_concept_alias_delete(token, business_concept_alias["id"])
      {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defand ~r/^if (?<result>[^"]+) is not "(?<status_code>[^"]+)", user (?<user_name>[^"]+) is able to see following list of aliases for business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)"$/,
    %{result: result, status_code: status_code, user_name: user_name, business_concept_name: business_concept_name, business_concept_type: business_concept_type, table: fields}, %{token_admin: token_admin} = _state do
    if result != status_code do
      assert_visible_aliases(token_admin, business_concept_name, business_concept_type, user_name, fields)
    end
  end

  defand ~r/^business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" and version "(?<version>[^"]+)" does not exist$/,
    %{business_concept_name: business_concept_name, business_concept_type: business_concept_type, version: version}, %{token_admin: token_admin} = _state do
    business_concept_version = String.to_integer(version)
    business_concept_tmp = business_concept_by_version_name_and_type(token_admin,
                                                                    business_concept_version,
                                                                    business_concept_name,
                                                                    business_concept_type)
    assert !business_concept_tmp
  end

  defand ~r/^user "(?<user_name>[^"]+)" is able to see following list of aliases for business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)"$/,
    %{user_name: user_name, business_concept_name: business_concept_name, business_concept_type: business_concept_type, table: fields}, _state do
    token = get_user_token(user_name)
    assert_visible_aliases(token, business_concept_name, business_concept_type, user_name, fields)
  end

  defand ~r/^some existing Business Concepts in the Domain "(?<domain_name>[^"]+)" with following data:$/,
    %{domain_name: domain_name,  table: fields},
    %{token_admin: token_admin} = state do
      domain = get_domain_by_name(token_admin, domain_name)
      business_concept_with_state_create(fields, token_admin, domain)
    {:ok, state}
  end

  defwhen ~r/^"(?<user_name>[^"]+)" tries to list all the Business Concepts with status "(?<status>[^"]+)"$/,
           %{user_name: user_name, status: status}, state do
     token = get_user_token(user_name)
     {:ok, 200, %{"data" => list_by_status}} = business_concept_list_with_status(token, status)
     {:ok, Map.merge(state, %{list_by_status: list_by_status, user_name: user_name})}
  end

  defthen ~r/^sees following business concepts:$/,
    %{table: [table]}, state do
    actual_list = state[:list_by_status]
    user_name = state[:user_name]
    expected_list = String.split(table[String.to_atom(user_name)], ",", trim: true)
    actual_list =  Enum.map(actual_list, fn(%{"name" => name}) -> name end)
    assert Enum.sort(actual_list) == Enum.sort(expected_list)
  end

  defand ~r/^"(?<user_name>[^"]+)" is able to view business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" with following data:$/,
    %{user_name: user_name, business_concept_name: business_concept_name, business_concept_type: business_concept_type, table: fields},
    %{token_admin: token_admin} = _state do

    token = get_user_token(user_name)
    business_concept_tmp = business_concept_by_name_and_type(token_admin, business_concept_name, business_concept_type)
    {_, http_status_code, %{"data" => business_concept}} = business_concept_show(token, business_concept_tmp["id"])
    assert rc_ok() == to_response_code(http_status_code)
    attrs = field_value_to_api_attrs(fields, token_admin, fixed_values())
    assert_attrs(attrs, business_concept)
  end

  defwhen ~r/^"(?<user_name>[^"]+)" tries to get the list of business concept types$/,
    %{user_name: user_name},
    state do

    token = get_user_token(user_name)
    {:ok, status_code, %{"data" => resp}} = index_templates(token)
    resp = Enum.map(resp, fn(x) -> %{type_name: Map.get(x, "name")} end)
    {:ok, Map.merge(state, %{status_code: status_code, user_name: user_name, business_concept_types: resp})}
  end

  defthen ~r/^user "(?<user_name>[^"]+)" is able to see following list of Business Concept Types$/,
    %{user_name: user_name, table: expected_list},
    state do

      assert user_name == state[:user_name]
      expected_list = Enum.map(expected_list, fn(type) -> type.type_name end)
      actual_list = Enum.map(state[:business_concept_types], fn(type) -> type[:type_name] end)
      assert Enum.sort(expected_list) == Enum.sort(actual_list)
  end

  defwhen ~r/^"(?<user_name>[^"]+)" tries to get the list of fields of business concept type "(?<bc_type>[^"]+)"$/,
    %{user_name: user_name, bc_type: bc_type},
    state do
    token = get_user_token(user_name)
    {:ok, status_code, %{"data" => resp}} = index_templates(token)
    [%{"content" => resp}] = Enum.filter(resp, fn(%{"name" => name}) -> name == bc_type end)
    {:ok, Map.merge(state, %{status_code: status_code, user_name: user_name, business_concept_type_fields: resp})}
  end

  defthen ~r/^user "(?<user_name>[^"]+)" is able to see following list of Business Concept Type Fields$/,
    %{user_name: user_name, table: expected_fields},
    state do

    assert user_name == state[:user_name]
    expected_fields = expected_fields
    |> Enum.map(fn(row) ->
      add_all_schema_fields(row)
    end)
    expected_fields = Enum.map(expected_fields, fn(field) -> CollectionUtils.stringify_keys(field) end)
    Enum.each(expected_fields, fn(expected_field) ->
      actual_field = Enum.find(state[:business_concept_type_fields], &(&1["name"] == expected_field["name"]))
      expected_field |> Map.keys |> Enum.map(fn(field_name) ->
        assert expected_field[field_name] == actual_field[field_name]
      end)
    end)
  end

  def assert_attr("content" = attr, value, %{} = target) do
    assert_attrs(value, target[attr])
  end

  def assert_attr("last_change_at" = attr, _value, %{} = target) do
    assert :ok == elem(DateTime.from_iso8601(target[attr]), 0)
  end

  def assert_attr("last_change_by" = attr, _value, %{} = target) do
    assert target[attr] != nil
  end

  def assert_attr("current" = attr, value, %{} = target) do
    assert String.to_existing_atom(value) == target[attr]
  end

  def assert_attr("version" = attr, value, %{} = target) do
    assert Integer.parse(value) == {target[attr], ""}
  end

  def assert_attr(attr, value, %{} = target) do
    assert value == target[attr]
  end

  def assert_attrs(%{} = attrs, %{} = target) do
    Enum.each(attrs, fn {attr, value} -> assert_attr(attr, value, target) end)
  end

  def add_schema_field(map, _name, ""), do: map
  def add_schema_field(map, :max_size, value) do
    Map.put(map, :max_size,  String.to_integer(value))
  end
  def add_schema_field(map, :values, values) do
    diff_values = values
      |> String.split(",")
      |> Enum.map(&(String.trim(&1)))
    Map.put(map, :values, diff_values)
  end
  def add_schema_field(map, :required, required) do
    Map.put(map, :required, required == "YES")
  end
  def add_schema_field(map, name, value), do: Map.put(map, name, value)

  def update_business_concept_version_map(field_map), do: update_in(field_map[:version], &String.to_integer(&1))

  def add_all_schema_fields(field_data) do
    Map.new
    |> add_schema_field(:name, field_data."Field")
    |> add_schema_field(:type, field_data."Format")
    |> add_schema_field(:max_size, field_data."Max Size")
    |> add_schema_field(:values, field_data."Values")
    |> add_schema_field(:required, field_data."Mandatory")
    |> add_schema_field(:default, field_data."Default Value")
    |> add_schema_field(:group, field_data."Group")
  end

  def assert_visible_aliases(token_admin, business_concept_name, business_concept_type, user_name, fields) do
    business_concept_version = business_concept_by_name_and_type(token_admin, business_concept_name, business_concept_type)
    business_concept_id = business_concept_version["id"]
    token = get_user_token(user_name)
    {_, status_code, %{"data" => business_concept_aliases}} = business_concept_alias_list(token, business_concept_id)
    assert rc_ok() == to_response_code(status_code)

    field_atoms = [:name]

    cooked_aliases = business_concept_aliases
    |> Enum.reduce([], &([map_keys_to_atoms(&1)| &2]))
    |> Enum.map(&(Map.take(&1, field_atoms)))
    |> Enum.sort

    cooked_fields = fields
    |> Enum.map(&(Map.take(&1, field_atoms)))
    |> Enum.sort

    assert cooked_aliases == cooked_fields

  end

  def map_keys_to_atoms(version), do: Map.new(version, &({String.to_atom(elem(&1, 0)), elem(&1, 1)}))

  def change_business_concept_status(token_admin, business_concept_id, status) do
    {_, status_code, %{"data" => business_concept_version}} = business_concept_show(token_admin, business_concept_id)
    assert rc_ok() == to_response_code(status_code)

    current_status = String.to_atom(business_concept_version["status"])
    desired_status = String.to_atom(status)
    case {current_status, desired_status} do
      {:draft, :draft} -> nil # do nohting
      {:draft, :rejected} ->
        business_concept_send_for_approval(token_admin, business_concept_id)
        business_concept_reject(token_admin, business_concept_id, "")
      {:draft, :pending_approval} ->
        business_concept_send_for_approval(token_admin, business_concept_id)
      {:draft, :published} ->
        business_concept_send_for_approval(token_admin, business_concept_id)
        business_concept_publish(token_admin, business_concept_id)
      {:published, :draft} ->
        business_concept_version(token_admin, business_concept_id)
    end
  end

  def field_value_to_api_attrs(table, token, fixed_values) do
    table
    |> Enum.reduce(%{}, fn(x, acc) -> Map.put(acc, Map.get(fixed_values, x."Field", x."Field"), x."Value") end)
    |> Map.split(Map.values(fixed_values))
    |> fn({f, v}) -> Map.put(f, "content", v) end.()
    |> load_related_to_ids(token)
  end

  def business_concept_with_state_create(table, token, domain) do
    Enum.each(table, fn(item) ->
      create_by_status_flow(item, token, domain)
    end)
  end

  def create_by_status_flow(%{Status: status} = business_concept, token, domain) do
    case status do
      "draft" ->
        attrs = business_concept
        |> Map.delete(:Status)
        |> Enum.map(fn({k, v}) -> %{"Field": Atom.to_string(k), "Value": v} end)
        |> field_value_to_api_attrs(token, fixed_values())
        {_, 201, _} = business_concept_create(token, domain["id"], attrs)
      "pending_approval" ->
        attrs = business_concept
        |> Map.delete(:Status)
        |> Enum.map(fn({k, v}) -> %{"Field": Atom.to_string(k), "Value": v} end)
        |> field_value_to_api_attrs(token, fixed_values())
        {_, 201, %{"data" => business_concept}} = business_concept_create(token, domain["id"], attrs)
        {_, 200} = business_concept_send_for_approval(token, business_concept["id"])
      "rejected" -> nil
      "published" -> nil
      "versioned" -> nil
      "deprecated" -> nil
    end
  end

  def load_related_to_ids(attrs, token) do
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
