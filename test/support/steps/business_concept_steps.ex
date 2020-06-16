defmodule TdBg.BusinessConceptSteps do
  @moduledoc false

  use Cabbage.Feature
  use ExUnit.CaseTemplate

  import TdBgWeb.BusinessConcept

  defand ~r/^an existing Business Concept type called "(?<business_concept_type>[^"]+)" with empty definition$/,
         %{business_concept_type: business_concept_type},
         state do
    Templates.create_template(business_concept_type, [])
    {:ok, Map.merge(state, %{bc_type: business_concept_type})}
  end

  defand ~r/^"(?<user_name>[^"]+)" tries to create a business concept in the Domain "(?<domain_name>[^"]+)" with following data:$/,
         %{user_name: user_name, domain_name: domain_name, table: fields},
         %{token_admin: token_admin} = state do
    token = get_user_token(user_name)

    attrs =
      fields
      |> field_value_to_api_attrs(fixed_values())
      |> Map.put("in_progress", false)

    domain = get_domain_by_name(token_admin, domain_name)
    {_, status_code, json_resp} = business_concept_version_create(token, domain["id"], attrs)
    {:ok, Map.merge(state, %{status_code: status_code, json_resp: json_resp})}
  end

  defand ~r/^"(?<user_name>[^"]+)" is able to view business concept "(?<business_concept_name>[^"]+)" as a child of Domain "(?<domain_name>[^"]+)" with following data:$/,
         %{
           user_name: user_name,
           business_concept_name: business_concept_name,
           domain_name: domain_name,
           table: fields
         },
         %{token_admin: token_admin} = state do
    token = get_user_token(user_name)
    domain = get_domain_by_name(token_admin, domain_name)
    business_concept_version = business_concept_version_by_name(token, business_concept_name)

    assert {_, http_status_code, %{"data" => business_concept_version}} =
             business_concept_version_show(token, business_concept_version["id"])

    assert rc_ok() == to_response_code(http_status_code)
    assert business_concept_version["name"] == business_concept_name
    assert business_concept_version["domain"]["id"] == domain["id"]
    attrs = field_value_to_api_attrs(fields, fixed_values())
    assert_attrs(attrs, business_concept_version)
    {:ok, state}
  end

  defand ~r/^an existing Business Concept type called "(?<business_concept_type>[^"]+)" with following definition:$/,
         %{business_concept_type: business_concept_type, table: table},
         %{} = state do
    schema =
      table
      |> Enum.map(fn row ->
        add_all_schema_fields(row)
      end)

    Templates.create_template(business_concept_type, [%{"name" => "group", "fields" => schema}])
    {:ok, Map.merge(state, %{bc_type: business_concept_type})}
  end

  defand ~r/^an existing Business Concept in the Domain "(?<domain_name>[^"]+)" with following data:$/,
         %{domain_name: domain_name, table: fields},
         state do
    token_admin =
      case state[:token_admin] do
        nil -> build_user_token("app-admin", is_admin: true)
        _ -> state[:token_admin]
      end

    domain = get_domain_by_name(token_admin, domain_name)

    attrs =
      fields
      |> field_value_to_api_attrs(fixed_values())
      |> Map.put("in_progress", false)

    business_concept_version_create(token_admin, domain["id"], attrs)
  end

  defand ~r/^"(?<user_name>[^"]+)" is not able to view business concept "(?<business_concept_name>[^"]+)" as a child of Domain "(?<domain_name>[^"]+)"$/,
         %{
           user_name: user_name,
           business_concept_name: business_concept_name,
           domain_name: domain_name
         },
         %{token_admin: token_admin} = state do
    token = get_user_token(user_name)
    domain = get_domain_by_name(token_admin, domain_name)
    business_concept_version = business_concept_version_by_name(token, business_concept_name)

    {_, http_status_code, %{"data" => business_concept_version}} =
      business_concept_version_show(token, business_concept_version["id"])

    assert rc_ok() == to_response_code(http_status_code)
    assert business_concept_version["name"] == business_concept_name
    assert business_concept_version["domain_id"] !== domain["id"]
    {:ok, state}
  end

  defand ~r/^an existing Business Concept of type "(?<business_concept_type>[^"]+)" in the Domain "(?<domain_name>[^"]+)" with following data:$/,
         %{
           business_concept_type: _business_concept_type,
           domain_name: domain_name,
           table: fields
         },
         %{token_admin: token_admin} = state do
    attrs =
      fields
      |> field_value_to_api_attrs(fixed_values())
      |> Map.put("in_progress", false)

    domain = get_domain_by_name(token_admin, domain_name)
    business_concept_version_create(token_admin, domain["id"], attrs)
    {:ok, state}
  end

  defwhen ~r/^"(?<user_name>[^"]+)" tries to modify a business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" with following data:$/,
          %{
            user_name: user_name,
            business_concept_name: business_concept_name,
            business_concept_type: business_concept_type,
            table: fields
          },
          %{token_admin: token_admin} = state do
    token = get_user_token(user_name)

    business_concept_version =
      business_concept_version_by_name(token_admin, business_concept_name)

    {_, _, %{"data" => current_business_concept}} =
      business_concept_version_show(token, business_concept_version["id"])

    business_concept_version_id = current_business_concept["id"]
    assert business_concept_type == current_business_concept["type"]

    attrs =
      fields
      |> field_value_to_api_attrs(fixed_values())
      |> Map.put("in_progress", false)

    {_, status_code, json_resp} =
      business_concept_version_update(token, business_concept_version_id, attrs)

    {:ok, Map.merge(state, %{status_code: status_code, json_resp: json_resp})}
  end

  # credo:disable-for-next-line Credo.Check.Readability.MaxLineLength
  defand ~r/^if result (?<result>[^"]+) is "(?<status_code>[^"]+)", user (?<user_name>[^"]+) is able to view business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" with following data:$/,
         %{
           result: result,
           status_code: status_code,
           user_name: user_name,
           business_concept_name: business_concept_name,
           business_concept_type: business_concept_type,
           table: fields
         },
         %{token_admin: token_admin} = state do
    token = get_user_token(user_name)

    if result == status_code do
      business_concept_tmp = business_concept_version_by_name(token_admin, business_concept_name)
      assert business_concept_type == business_concept_tmp["type"]

      {_, http_status_code, %{"data" => business_concept_version}} =
        business_concept_version_show(token, business_concept_tmp["id"])

      assert rc_ok() == to_response_code(http_status_code)
      attrs = field_value_to_api_attrs(fields, fixed_values())
      assert_attrs(attrs, business_concept_version)
      {:ok, Map.merge(state, %{business_concept_version: business_concept_version})}
    else
      {:ok, state}
    end
  end

  defwhen ~r/^"(?<user_name>[^"]+)" tries to send for approval a business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)"$/,
          %{
            user_name: user_name,
            business_concept_name: business_concept_name,
            business_concept_type: business_concept_type
          },
          %{token_admin: token_admin} = state do
    token = get_user_token(user_name)

    business_concept =
      business_concept_version_by_name_and_type(
        token_admin,
        business_concept_name,
        business_concept_type
      )

    business_concept_version_id = business_concept["id"]

    {_, status_code, _} =
      business_concept_version_send_for_approval(token, business_concept_version_id)

    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defand ~r/^the business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" has been submitted for approval$/,
         %{
           business_concept_name: business_concept_name,
           business_concept_type: business_concept_type
         },
         %{token_admin: token_admin} = state do
    business_concept_version =
      business_concept_version_by_name_and_type(
        token_admin,
        business_concept_name,
        business_concept_type
      )

    business_concept_version_id = business_concept_version["id"]
    business_concept_version_send_for_approval(token_admin, business_concept_version_id)
    {:ok, state}
  end

  defand ~r/^the business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" has been redrafted$/,
         %{
           business_concept_name: business_concept_name,
           business_concept_type: business_concept_type
         },
         %{token_admin: token_admin} = state do
    business_concept_version =
      business_concept_version_by_name_and_type(
        token_admin,
        business_concept_name,
        business_concept_type
      )

    business_concept_version_id = business_concept_version["id"]
    business_concept_version_redraft(token_admin, business_concept_version_id)
    {:ok, state}
  end

  defand ~r/^the business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" has been published$/,
         %{
           business_concept_name: business_concept_name,
           business_concept_type: business_concept_type
         },
         %{token_admin: token_admin} = state do
    business_concept_version =
      business_concept_version_by_name_and_type(
        token_admin,
        business_concept_name,
        business_concept_type
      )

    business_concept_version_id = business_concept_version["id"]
    business_concept_version_publish(token_admin, business_concept_version_id)
    {:ok, state}
  end

  defand ~r/^the business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" has been rejected with reason "(?<reason>[^"]+)"$/,
         %{
           business_concept_name: business_concept_name,
           business_concept_type: business_concept_type,
           reason: reason
         },
         %{token_admin: token_admin} = state do
    business_concept_version =
      business_concept_version_by_name_and_type(
        token_admin,
        business_concept_name,
        business_concept_type
      )

    business_concept_version_id = business_concept_version["id"]
    business_concept_version_reject(token_admin, business_concept_version_id, reason)
    {:ok, state}
  end

  defand ~r/^the business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" has been copied as a new draft$/,
         %{
           business_concept_name: business_concept_name,
           business_concept_type: business_concept_type
         },
         %{token_admin: token_admin} = state do
    business_concept_version =
      business_concept_version_by_name_and_type(
        token_admin,
        business_concept_name,
        business_concept_type
      )

    business_concept_version_id = business_concept_version["id"]
    business_concept_new_version(token_admin, business_concept_version_id)
    {:ok, state}
  end

  defwhen ~r/^(?<user_name>[^"]+) tries to publish a business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)"$/,
          %{
            user_name: user_name,
            business_concept_name: business_concept_name,
            business_concept_type: business_concept_type
          },
          %{token_admin: token_admin} = state do
    token = get_user_token(user_name)

    business_concept =
      business_concept_version_by_name_and_type(
        token_admin,
        business_concept_name,
        business_concept_type
      )

    business_concept_version_id = business_concept["id"]
    {_, status_code, _} = business_concept_version_publish(token, business_concept_version_id)
    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defwhen ~r/^(?<user_name>[^"]+) tries to reject a business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" and reject reason "(?<reject_reason>[^"]+)"$/,
          %{
            user_name: user_name,
            business_concept_name: business_concept_name,
            business_concept_type: business_concept_type,
            reject_reason: reject_reason
          },
          %{token_admin: token_admin} = state do
    token = get_user_token(user_name)

    business_concept =
      business_concept_version_by_name_and_type(
        token_admin,
        business_concept_name,
        business_concept_type
      )

    business_concept_version_id = business_concept["id"]

    {_, status_code, _} =
      business_concept_version_reject(token, business_concept_version_id, reject_reason)

    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  # credo:disable-for-next-line Credo.Check.Readability.MaxLineLength
  defand ~r/^if result (?<result>[^"]+) is "(?<status_code>[^"]+)", user (?<user_name>[^"]+) is able to view business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" and version "(?<version>[^"]+)" with following data:$/,
         %{
           result: result,
           status_code: status_code,
           user_name: user_name,
           business_concept_name: business_concept_name,
           business_concept_type: business_concept_type,
           version: version,
           table: fields
         },
         %{token_admin: token_admin} = state do
    token = get_user_token(user_name)
    version = String.to_integer(version)

    if result == status_code do
      business_concept_version =
        business_concept_by_version_name_and_type(
          token_admin,
          version,
          business_concept_name,
          business_concept_type
        )

      assert version == business_concept_version["version"]
      assert business_concept_type == business_concept_version["type"]

      {_, http_status_code, %{"data" => business_concept_version}} =
        business_concept_version_show(token, business_concept_version["id"])

      assert rc_ok() == to_response_code(http_status_code)
      attrs = field_value_to_api_attrs(fields, fixed_values())
      assert_attrs(attrs, business_concept_version)
      {:ok, Map.merge(state, %{business_concept_version: business_concept_version})}
    else
      {:ok, state}
    end
  end

  defand ~r/^business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" has been modified with following data:$/,
         %{
           business_concept_name: business_concept_name,
           business_concept_type: business_concept_type,
           table: fields
         },
         %{token_admin: token_admin} = state do
    business_concept = business_concept_version_by_name(token_admin, business_concept_name)
    assert business_concept_type == business_concept["type"]

    attrs =
      fields
      |> field_value_to_api_attrs(fixed_values())
      |> Map.put("in_progress", false)

    case business_concept["status"] do
      "published" ->
        {:ok, _, %{"data" => %{"id" => business_concept_version_id}}} =
          business_concept_new_version(token_admin, business_concept["id"])

        business_concept_version_update(token_admin, business_concept_version_id, attrs)

      "draft" ->
        business_concept_version_update(token_admin, business_concept["id"], attrs)

      _ ->
        raise("Invalid status for modification")
    end

    {:ok, state}
  end

  defwhen ~r/^(?<user_name>[^"]+) tries to delete a business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)"$/,
          %{
            user_name: user_name,
            business_concept_name: business_concept_name,
            business_concept_type: business_concept_type
          },
          %{token_admin: token_admin} = state do
    business_concept_tmp =
      business_concept_version_by_name_and_type(
        token_admin,
        business_concept_name,
        business_concept_type
      )

    assert business_concept_tmp
    token = get_user_token(user_name)
    business_concept_version_id = business_concept_tmp["id"]
    {_, status_code} = business_concept_version_delete(token, business_concept_version_id)

    {:ok,
     Map.merge(state, %{
       status_code: status_code,
       deleted_business_concept_version_id: business_concept_version_id
     })}
  end

  # credo:disable-for-next-line Credo.Check.Readability.MaxLineLength
  defand ~r/^if result (?<result>[^"]+) is "(?<status_code>[^"]+)", user (?<user_name>[^"]+) is not able to view business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)"$/,
         %{
           result: result,
           status_code: status_code,
           user_name: user_name,
           business_concept_name: _business_concept_name,
           business_concept_type: _business_concept_type
         },
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

  # credo:disable-for-next-line Credo.Check.Readability.MaxLineLength
  defand ~r/^if result (?<result>[^"]+) is not "(?<status_code>[^"]+)", user (?<user_name>[^"]+) is able to view business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" and version "(?<version>[^"]+)" with following data:$/,
         %{
           result: result,
           status_code: status_code,
           user_name: user_name,
           business_concept_name: business_concept_name,
           business_concept_type: business_concept_type,
           version: version,
           table: fields
         },
         %{token_admin: token_admin} = state do
    token = get_user_token(user_name)
    version = String.to_integer(version)

    if result != status_code do
      business_concept_version =
        business_concept_by_version_name_and_type(
          token_admin,
          version,
          business_concept_name,
          business_concept_type
        )

      assert version == business_concept_version["version"]
      assert business_concept_type == business_concept_version["type"]

      {_, http_status_code, %{"data" => business_concept_version}} =
        business_concept_version_show(token, business_concept_version["id"])

      assert rc_ok() == to_response_code(http_status_code)
      attrs = field_value_to_api_attrs(fields, fixed_values())
      assert_attrs(attrs, business_concept_version)
      {:ok, state}
    else
      {:ok, state}
    end
  end

  defand ~r/^user (?<user_name>[^"]+) is able to view business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" and version "(?<version>[^"]+)" with following data:$/,
         %{
           user_name: user_name,
           business_concept_name: business_concept_name,
           business_concept_type: business_concept_type,
           version: version,
           table: fields
         },
         %{token_admin: token_admin} = state do
    version = String.to_integer(version)

    business_concept_version =
      business_concept_by_version_name_and_type(
        token_admin,
        version,
        business_concept_name,
        business_concept_type
      )

    assert business_concept_version
    assert business_concept_type == business_concept_version["type"]
    token = get_user_token(user_name)

    {_, http_status_code, %{"data" => business_concept_version}} =
      business_concept_version_show(token, business_concept_version["id"])

    assert rc_ok() == to_response_code(http_status_code)
    attrs = field_value_to_api_attrs(fields, fixed_values())
    assert_attrs(attrs, business_concept_version)
    {:ok, state}
  end

  # credo:disable-for-next-line Credo.Check.Readability.MaxLineLength
  defand ~r/^if result (?<result>[^"]+) is "(?<status_code>[^"]+)",  business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" and version "(?<version>[^"]+)" does not exist$/,
         %{
           result: result,
           status_code: status_code,
           business_concept_name: business_concept_name,
           business_concept_type: business_concept_type,
           version: version
         },
         %{token_admin: token_admin} = _state do
    if result == status_code do
      business_concept_version = String.to_integer(version)

      business_concept_tmp =
        business_concept_by_version_name_and_type(
          token_admin,
          business_concept_version,
          business_concept_name,
          business_concept_type
        )

      assert !business_concept_tmp
    end
  end

  defwhen ~r/^(?<user_name>[^"]+) tries to deprecate a business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)"$/,
          %{
            user_name: user_name,
            business_concept_name: business_concept_name,
            business_concept_type: business_concept_type
          },
          %{token_admin: token_admin} = state do
    token = get_user_token(user_name)

    business_concept =
      business_concept_version_by_name_and_type(
        token_admin,
        business_concept_name,
        business_concept_type
      )

    business_concept_version_id = business_concept["id"]
    {_, status_code, _} = business_concept_version_deprecate(token, business_concept_version_id)
    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defwhen ~r/^(?<user_name>[^"]+) tries to query history for a business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)"$/,
          %{
            user_name: user_name,
            business_concept_name: business_concept_name,
            business_concept_type: business_concept_type
          },
          %{token_admin: token_admin} = state do
    business_concept_version =
      business_concept_version_by_name_and_type(
        token_admin,
        business_concept_name,
        business_concept_type
      )

    business_concept_version_id = business_concept_version["id"]
    token = get_user_token(user_name)

    {_, status_code, %{"data" => business_concept_versions}} =
      business_concept_version_versions(token, business_concept_version_id)

    assert rc_ok() == to_response_code(status_code)
    {:ok, Map.merge(state, %{business_concept_versions: business_concept_versions})}
  end

  defand ~r/^business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" and version "(?<version>[^"]+)" does not exist$/,
         %{
           business_concept_name: business_concept_name,
           business_concept_type: business_concept_type,
           version: version
         },
         %{token_admin: token_admin} = _state do
    business_concept_version = String.to_integer(version)

    business_concept_tmp =
      business_concept_by_version_name_and_type(
        token_admin,
        business_concept_version,
        business_concept_name,
        business_concept_type
      )

    assert !business_concept_tmp
  end

  defand ~r/^some existing Business Concepts in the Domain "(?<domain_name>[^"]+)" with following data:$/,
         %{domain_name: domain_name, table: fields},
         %{token_admin: token_admin} = state do
    domain = get_domain_by_name(token_admin, domain_name)
    business_concept_with_state_create(fields, token_admin, domain)
    {:ok, state}
  end

  defand ~r/^"(?<user_name>[^"]+)" is able to view business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" with following data:$/,
         %{
           user_name: user_name,
           business_concept_name: business_concept_name,
           business_concept_type: business_concept_type,
           table: fields
         },
         %{token_admin: token_admin} = _state do
    token = get_user_token(user_name)

    business_concept_version =
      business_concept_version_by_name_and_type(
        token_admin,
        business_concept_name,
        business_concept_type
      )

    {_, http_status_code, %{"data" => business_concept_version}} =
      business_concept_version_show(token, business_concept_version["id"])

    assert rc_ok() == to_response_code(http_status_code)
    attrs = field_value_to_api_attrs(fields, fixed_values())
    assert_attrs(attrs, business_concept_version)
  end

  defthen ~r/^user "(?<user_name>[^"]+)" is able to see following list of Business Concept Types$/,
          %{user_name: user_name, table: expected_list},
          state do
    assert user_name == state[:user_name]
    expected_list = Enum.map(expected_list, fn type -> type.type_name end)
    actual_list = Enum.map(state[:business_concept_types], fn type -> type[:type_name] end)
    assert Enum.sort(expected_list) == Enum.sort(actual_list)
  end

  defthen ~r/^user "(?<user_name>[^"]+)" is able to see following list of Business Concept Type Fields$/,
          %{user_name: user_name, table: expected_fields},
          state do
    alias TdBg.Utils.CollectionUtils
    assert user_name == state[:user_name]

    expected_fields = Enum.map(expected_fields, &add_all_schema_fields/1)

    expected_fields = Enum.map(expected_fields, &CollectionUtils.stringify_keys/1)

    Enum.each(expected_fields, fn expected_field ->
      actual_field =
        Enum.find(state[:business_concept_type_fields], &(&1["name"] == expected_field["name"]))

      expected_field
      |> Map.keys()
      |> Enum.map(fn field_name ->
        assert expected_field[field_name] == actual_field[field_name]
      end)
    end)
  end

  defwhen ~r/^"(?<user_name>[^"]+)" uploads business concepts with the following data:$/,
          %{user_name: user_name, table: to_upload},
          state do
    headers = [
      :template,
      :domain,
      :name,
      :description,
      :Formula,
      :Values
    ]

    [%{template: template} | _] = to_upload

    schema = [
      %{
        "name" => "group",
        "fields" => [
          %{name: "Formula", type: "string", cardinality: "?", values: %{}},
          %{name: "Values", type: "string", cardinality: "?", values: %{}}
        ]
      }
    ]

    Templates.create_template(template, schema)

    business_concepts =
      to_upload
      |> Enum.reduce([], fn item, acc ->
        row = Enum.reduce(headers, [], &(&2 ++ [Map.get(item, &1)]))
        [row | acc]
      end)
      |> List.insert_at(0, headers)
      |> CSV.encode(separator: ?;)
      |> Enum.to_list()
      |> Enum.join()

    token = get_user_token(user_name)
    {:ok, status_code} = business_concept_version_upload(token, business_concepts)
    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defthen ~r/^"(?<user_name>[^"]+)" is able to view the following uploaded business concepts:$/,
          %{user_name: user_name, table: values},
          _state do
    token = get_user_token(user_name)
    {:ok, 200, %{"data" => bcv_list}} = business_concept_version_list(token)

    business_concept_versions =
      Enum.reduce(bcv_list, [], fn business_concept_version, acc ->
        {:ok, 200, %{"data" => data}} =
          business_concept_version_show(token, business_concept_version["id"])

        acc ++ [data]
      end)

    assert length(business_concept_versions) == length(values)

    Enum.each(business_concept_versions, fn concept ->
      value = Enum.find(values, fn v -> concept["name"] == v.name end)
      assert concept["name"] == value.name
      assert concept["type"] == value.template
      assert concept["domain"]["name"] == value.domain
      assert to_plain_text(concept["description"]) == value.description
      assert concept["content"]["Formula"] == value."Formula"
      assert concept["content"]["Values"] == value."Values"
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

  def assert_attr("description" = attr, value, %{} = target) do
    assert value == to_plain_text(target[attr])
  end

  def assert_attr(attr, value, %{} = target) do
    assert value == target[attr]
  end

  def assert_attrs(%{} = attrs, %{} = target) do
    Enum.each(attrs, fn {attr, value} -> assert_attr(attr, value, target) end)
  end

  def add_schema_field(map, _name, ""), do: map

  def add_schema_field(map, "max_size", value) do
    Map.put(map, "max_size", String.to_integer(value))
  end

  def add_schema_field(map, "values", values) do
    diff_values =
      values
      |> String.split(",")
      |> Enum.map(&String.trim/1)

    Map.put(map, "values", %{"fixed" => diff_values})
  end

  def add_schema_field(map, name, value), do: Map.put(map, name, value)

  def update_business_concept_version_map(field_map),
    do: update_in(field_map[:version], &String.to_integer/1)

  def add_all_schema_fields(field_data) do
    Map.new()
    |> add_schema_field("name", field_data."Field")
    |> add_schema_field("type", "string")
    |> add_schema_field("max_size", field_data."Max Size")
    |> add_schema_field("values", field_data."Values")
    |> add_schema_field("cardinality", field_data."Cardinality")
    |> add_schema_field("default", field_data."Default Value")
    |> add_schema_field("group", field_data."Group")
  end

  def map_keys_to_atoms(version),
    do: Map.new(version, &{String.to_atom(elem(&1, 0)), elem(&1, 1)})

  def field_value_to_api_attrs(table, fixed_values) do
    table
    |> Enum.reduce(%{}, fn x, acc ->
      Map.put(acc, Map.get(fixed_values, x."Field", x."Field"), x."Value")
    end)
    |> Map.split(Map.values(fixed_values))
    |> (fn {f, v} -> Map.put(f, "content", v) end).()
  end

  def business_concept_with_state_create(table, token, domain) do
    Enum.each(table, fn item ->
      create_by_status_flow(item, token, domain)
    end)
  end

  def create_by_status_flow(%{Status: status} = business_concept_version, token, domain) do
    case status do
      "draft" ->
        attrs =
          business_concept_version
          |> Map.delete(:Status)
          |> Enum.map(fn {k, v} -> %{Field: Atom.to_string(k), Value: v} end)
          |> field_value_to_api_attrs(fixed_values())

        {_, 201, _} = business_concept_version_create(token, domain["id"], attrs)

      "pending_approval" ->
        attrs =
          business_concept_version
          |> Map.delete(:Status)
          |> Enum.map(fn {k, v} -> %{Field: Atom.to_string(k), Value: v} end)
          |> field_value_to_api_attrs(fixed_values())

        {_, 201, %{"data" => business_concept_version}} =
          business_concept_version_create(token, domain["id"], attrs)

        {_, 200} =
          business_concept_version_send_for_approval(token, business_concept_version["id"])

      "rejected" ->
        nil

      "published" ->
        nil

      "versioned" ->
        nil

      "deprecated" ->
        nil
    end
  end
end
