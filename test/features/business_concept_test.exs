defmodule TrueBG.BusinessConceptTest do
  use Cabbage.Feature, async: false, file: "business_concept.feature"
  use TrueBGWeb.ConnCase

  # import TrueBGWeb.Router.Helpers
  import TrueBGWeb.ResponseCode
  import TrueBGWeb.User, only: :functions
  import TrueBGWeb.Taxonomy, only: :functions
  import TrueBGWeb.AclEntry, only: :functions
  import TrueBGWeb.Authentication, only: :functions

  alias Poison, as: JSON

  @endpoint TrueBGWeb.Endpoint
  @headers {"Content-type", "application/json"}
  @fixed_values %{"Type" => "type",
                  "Name" => "name",
                  "Description" => "description",
                  "Status" => "status",
                  "Last Modification" => "last_change",
                  "Last User" => "modifier",
                  "Version" => "version",
                  "Reject Reason" => "reject_reason",
                  "Modification Comments" => "mod_comments"
                  }

  # Scenario: Create a simple business concept
  defgiven ~r/^an existing Domain Group called "(?<domain_group_name>[^"]+)"$/,
    %{domain_group_name: domain_group_name}, state do
    token_admin = case state[:token_admin] do
                nil -> build_user_token("app-admin", true)
                _ -> state[:token_admin]
              end
    {_, status_code, _json_resp} = domain_group_create(token_admin, %{name: domain_group_name})
    assert rc_created() == to_response_code(status_code)
    {:ok, Map.merge(state, %{token_admin: token_admin})}
  end

  defand ~r/^an existing Domain Group called "(?<child_domain_group_name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)"$/,
          %{child_domain_group_name: child_domain_group_name, domain_group_name: domain_group_name}, %{token_admin: token_admin} = _state do

    parent = get_domain_group_by_name(token_admin, domain_group_name)
    {_, _status_code, _json_resp} = domain_group_create(token_admin,  %{name: child_domain_group_name, parent_id: parent["id"]})
  end

  defand ~r/^an existing Data Domain called "(?<name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)"$/,
          %{name: name, domain_group_name: domain_group_name}, %{token_admin: token_admin} = _state do
    domain_group = get_domain_group_by_name(token_admin, domain_group_name)
    assert domain_group["name"] == domain_group_name
    {_, _status_code, json_resp} = data_domain_create(token_admin, %{name: name, domain_group_id: domain_group["id"]})
    data_domain = json_resp["data"]
    assert data_domain["domain_group_id"] == domain_group["id"]
  end

  defand ~r/^an existing Business Concept type called "(?<business_concept_type>[^"]+)" with empty definition$/,
    %{business_concept_type: business_concept_type}, state do
    filename = Application.get_env(:trueBG, :bc_schema_location)
    {:ok, file} = File.open filename, [:write, :utf8]
    json_schema = [{business_concept_type, []}] |> Map.new |> JSON.encode!
    IO.binwrite file, json_schema
    File.close file
    {:ok, Map.merge(state, %{bc_type: business_concept_type})}
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" is logged in the application with password "(?<password>[^"]+)"$/, %{user_name: user_name, password: _password}, state do
    token = build_user_token(user_name, user_name == "app-admin")
    {:ok, Map.merge(state, %{token: token, token_owner: user_name})}
  end

  defand ~r/^"(?<user_name>[^"]+)" tries to create a business concept in the Data Domain "(?<data_domain_name>[^"]+)" with following data:$/,
          %{user_name: user_name, data_domain_name: data_domain_name, table: fields},
          %{token_owner: token_owner, token: token, token_admin: token_admin} = state do

    assert user_name == token_owner

    attrs = field_value_to_api_attrs(fields, @fixed_values)
    data_domain = get_data_domain_by_name(token_admin, data_domain_name)

    {_, status_code, _} = business_concept_create(token, data_domain["id"], attrs)
    {:ok, Map.merge(state, %{status_code: status_code})}

  end

  defthen ~r/^the system returns a result with code "(?<status_code>[^"]+)"$/,
          %{status_code: status_code}, %{status_code: http_status_code} = state do
    assert status_code == to_response_code(http_status_code)
    {:ok, Map.merge(state, %{})}
  end

  def assert_attr("content" = attr, value, %{} = target) do
    assert_attrs(value, target[attr])
  end

  def assert_attr("last_change" = attr, _value, %{} = target) do
    assert :ok == elem(DateTime.from_iso8601(target[attr]), 0)
  end

  def assert_attr("modifier" = attr, _value, %{} = target) do
    assert target[attr] != nil
  end

  def assert_attr("version" = attr, value, %{} = target) do
    assert Integer.parse(value) == {target[attr], ""}
  end

  def assert_attr(attr, value, %{} = target) do
    assert value == target[attr]
  end

  defp assert_attrs(%{} = attrs, %{} = target) do
    Enum.each(attrs, fn {attr, value} -> assert_attr(attr, value, target) end)
  end

  defand ~r/^"(?<user_name>[^"]+)" is able to view business concept "(?<business_concept_name>[^"]+)" as a child of Data Domain "(?<data_domain_name>[^"]+)" with following data:$/,
    %{user_name: user_name, business_concept_name: business_concept_name, data_domain_name: data_domain_name, table: fields},
    %{token_admin: token_admin, token: token, token_owner: token_owner} = state do

      assert user_name == token_owner
      data_domain = get_data_domain_by_name(token_admin, data_domain_name)
      business_concept = business_concept_by_name(token, business_concept_name)
      {_, http_status_code, %{"data" => business_concept}} = business_concept_show(token, business_concept["id"])
      assert rc_ok() == to_response_code(http_status_code)
      assert business_concept["name"] == business_concept_name
      assert business_concept["data_domain_id"] == data_domain["id"]
      attrs = field_value_to_api_attrs(fields, @fixed_values)
      assert_attrs(attrs, business_concept)
      {:ok, Map.merge(state, %{})}
  end

  # Scenario: Create a business concept with dinamic data
  defp add_schema_field(map, _name, ""), do: map
  defp add_schema_field(map, :max_size, value) do
    Map.put(map, :max_size,  String.to_integer(value))
  end
  defp add_schema_field(map, :values, values) do
    diff_values = values
      |> String.split(",")
      |> Enum.map(&(String.trim(&1)))
    Map.put(map, :values, diff_values)
  end
  defp add_schema_field(map, :required, required) do
    Map.put(map, :required, required == "YES")
  end
  defp add_schema_field(map, name, value), do: Map.put(map, name, value)

  defand ~r/^an existing Business Concept type called "(?<business_concept_type>[^"]+)" with following definition:$/,
          %{business_concept_type: business_concept_type, table: table},
          %{} = state do

    schema = table
    |> Enum.map(fn(row) ->
      Map.new
      |> add_schema_field(:name, row."Field")
      |> add_schema_field(:type, row."Format")
      |> add_schema_field(:max_size, row."Max Size")
      |> add_schema_field(:values, row."Values")
      |> add_schema_field(:required, row."Mandatory")
      |> add_schema_field(:default, row."Default Value")
    end)

    json_schema = %{business_concept_type  => schema} |> JSON.encode!

    path = Application.get_env(:trueBG, :bc_schema_location)
    File.write!(path, json_schema, [:write, :utf8])

    {:ok, Map.merge(state, %{bc_type: business_concept_type})}
  end

  # Scenario Outline: Creating a business concept depending on your role

  defand ~r/^following users exist with the indicated role in Data Domain "(?<data_domain_name>[^"]+)"$/,
          %{data_domain_name: data_domain_name, table: table}, %{token_admin: token_admin} = state do

    data_domain = get_data_domain_by_name(token_admin, data_domain_name)
    assert data_domain_name == data_domain["name"]

    create_user_and_acl_entries_fn = fn(x) ->
      user_name = x[:user]
      role_name = x[:role]
      principal_id = create_user(user_name).id
      %{"id" => role_id} = get_role_by_name(token_admin, role_name)
      acl_entry_params = %{principal_type: "user", principal_id: principal_id, resource_type: "data_domain", resource_id: data_domain["id"], role_id: role_id}
      {_, _status_code, _json_resp} = acl_entry_create(token_admin , acl_entry_params)
    end

    users = table |> Enum.map(create_user_and_acl_entries_fn)

    {:ok, Map.merge(state, %{users: users})}
  end

  # Scenario: User should not be able to create a business concept with same type and name as an existing one
  defand ~r/^an existing Business Concept in the Data Domain "(?<data_domain_name>[^"]+)" with following data:$/,
    %{data_domain_name: data_domain_name, table: fields}, state do
    #Retriving token
    token_admin = case state[:token_admin] do
                nil -> build_user_token("app-admin", true)
                _ -> state[:token_admin]
              end

    #Retrieve data domain by name in order to create a business concept
    data_domain = get_data_domain_by_name(token_admin, data_domain_name)
    #Create Business Concept with the given data and the admin token
    attrs = field_value_to_api_attrs(fields, @fixed_values)
    # Creamos el busines concept para cuando tenga que recuperarlo
    business_concept_create(token_admin, data_domain["id"], attrs)
  end

  defand ~r/^"(?<user_name>[^"]+)" is not able to view business concept "(?<business_concept_name>[^"]+)" as a child of Data Domain "(?<data_domain_name>[^"]+)"$/,
    %{user_name: user_name, business_concept_name: business_concept_name, data_domain_name: data_domain_name},
    %{token_admin: token_admin, token: token, token_owner: token_owner} = state do

    assert user_name == token_owner
    data_domain = get_data_domain_by_name(token_admin, data_domain_name)
    business_concept = business_concept_by_name(token, business_concept_name)
    {_, http_status_code, %{"data" => business_concept}} = business_concept_show(token, business_concept["id"])
    assert rc_ok() == to_response_code(http_status_code)
    assert business_concept["name"] == business_concept_name
    assert business_concept["data_domain_id"] !== data_domain["id"]
    {:ok, Map.merge(state, %{})}

  end

  # Scenario Outline: Modification of existing Business Concept in Draft status

  defand ~r/^an existing Business Concept of type "(?<business_concept_type>[^"]+)" in the Data Domain "(?<data_domain_name>[^"]+)" with following data:$/,
    %{business_concept_type: _business_concept_type, data_domain_name: data_domain_name,  table: fields},
    %{token_admin: token_admin} = state do
      attrs = field_value_to_api_attrs(fields, @fixed_values)
      data_domain = get_data_domain_by_name(token_admin, data_domain_name)
      business_concept_create(token_admin, data_domain["id"], attrs)
    {:ok, Map.merge(state, %{})}
  end

  defwhen ~r/^(?<user_name>[^"]+) tries to modify a business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" with following data:$/,
    %{user_name: user_name, business_concept_name: business_concept_name, business_concept_type: business_concept_type, table: fields},
    %{token_admin: token_admin, token: token, token_owner: token_owner} = state do
      assert user_name == token_owner
      business_concept = business_concept_by_name(token_admin, business_concept_name)
      assert business_concept_type == business_concept["type"]
      attrs = field_value_to_api_attrs(fields, @fixed_values)
      {_, status_code, _} = business_concept_update(token, business_concept["id"],  attrs)
      {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defand ~r/^if result (?<result>[^"]+) is "(?<status_code>[^"]+)", user (?<user_name>[^"]+) is able to view business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" with follwing data:$/,
    %{result: result, status_code: status_code, user_name: user_name, business_concept_name: business_concept_name, business_concept_type: business_concept_type, table: fields},
    %{token_admin: token_admin, token: token, token_owner: token_owner} = state do

    assert user_name == token_owner

    if result == status_code do
      business_concept_tmp = business_concept_by_name(token_admin, business_concept_name)
      assert business_concept_type == business_concept_tmp["type"]
      {_, http_status_code, %{"data" => business_concept}} = business_concept_show(token, business_concept_tmp["id"])
      assert rc_ok() == to_response_code(http_status_code)
      attrs = field_value_to_api_attrs(fields, @fixed_values)
      assert_attrs(attrs, business_concept)
      {:ok, Map.merge(state, %{business_concept: business_concept})}
    else
      {:ok, Map.merge(state, %{})}
    end
  end

 defwhen ~r/^"(?<user_name>[^"]+)" tries to send for approval a business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)"$/,
          %{user_name: user_name, business_concept_name: business_concept_name, business_concept_type: business_concept_type},
          %{token_owner: token_owner, token: token, token_admin: token_admin} = state do

    assert token_owner == user_name
    business_concept = business_concept_by_name_and_type(token_admin, business_concept_name, business_concept_type)
    {_, status_code} = business_concept_send_for_approval(token, business_concept["id"])
    {:ok, Map.merge(state, %{status_code: status_code})}

 end

 # Scenario Outline: Publish existing Business Concept in Pending Approval status

 defand ~r/^the status of business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" is set to "(?<status>[^"]+)"$/,
  %{business_concept_name: business_concept_name, business_concept_type: business_concept_type, status: status},
  %{token_admin: token_admin} = state do
    business_concept = business_concept_by_name_and_type(token_admin, business_concept_name, business_concept_type)

    current_status = String.to_atom(business_concept["status"])
    desired_status = String.to_atom(status)
    case {current_status, desired_status} do
      {:draft, :pending_approval} ->
        business_concept_send_for_approval(token_admin, business_concept["id"])
      {:draft, :published} ->
        business_concept_send_for_approval(token_admin, business_concept["id"])
        business_concept_publish(token_admin, business_concept["id"])
    end

    {:ok, Map.merge(state, %{})}
  end

  defwhen ~r/^(?<user_name>[^"]+) tries to publish a business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)"$/,
    %{user_name: user_name, business_concept_name: business_concept_name, business_concept_type: business_concept_type},
    %{token_admin: token_admin, token: token, token_owner: token_owner} = state do
      assert user_name == token_owner
      business_concept = business_concept_by_name_and_type(token_admin, business_concept_name, business_concept_type)
      {_, status_code} = business_concept_publish(token, business_concept["id"])
      {:ok, Map.merge(state, %{status_code: status_code})}
  end

  # Scenario Outline: Reject existing Business Concept in Pending Approval status

  defwhen ~r/^(?<user_name>[^"]+) tries to reject a business concept with name "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" and reject reason "(?<reject_reason>[^"]+)"$/,
    %{user_name: user_name, business_concept_name: business_concept_name, business_concept_type: business_concept_type, reject_reason: reject_reason},
    %{token_admin: token_admin, token: token, token_owner: token_owner} = state do
      assert user_name == token_owner
      business_concept = business_concept_by_name_and_type(token_admin, business_concept_name, business_concept_type)
      {_, status_code} = business_concept_reject(token, business_concept["id"], reject_reason)

      {:ok, Map.merge(state, %{status_code: status_code})}
  end

  # Scenario Outline: Modification of existing Business Concept in Published status

  defand ~r/^if result (?<result>[^"]+) is "(?<status_code>[^"]+)", user (?<user_name>[^"]+) is able to view business concept "(?<business_concept_name>[^"]+)" of type "(?<business_concept_type>[^"]+)" and version "(?<version>[^"]+)" with follwing data::$/,
    %{result: result, status_code: status_code, user_name: user_name, business_concept_name: business_concept_name, business_concept_type: business_concept_type, version: version, table: fields},
    %{token_admin: token_admin, token: token, token_owner: token_owner} = state do

      assert user_name == token_owner

      business_concept_version = String.to_integer(version)

      if result == status_code do
        business_concept_tmp = business_concept_by_version_name_and_type(
                    token_admin, business_concept_version, business_concept_name,
                    business_concept_type)
        assert business_concept_version == business_concept_tmp["version"]
        assert business_concept_type == business_concept_tmp["type"]
        {_, http_status_code, %{"data" => business_concept}} = business_concept_show(token, business_concept_tmp["id"])
        assert rc_ok() == to_response_code(http_status_code)
        attrs = field_value_to_api_attrs(fields, @fixed_values)
        assert_attrs(attrs, business_concept)
        {:ok, Map.merge(state, %{business_concept: business_concept})}
      else
        {:ok, Map.merge(state, %{})}
      end
  end

  defp field_value_to_api_attrs(table, fixed_values) do
    table
      |> Enum.reduce(%{}, fn(x, acc) -> Map.put(acc, Map.get(fixed_values, x."Field", x."Field"), x."Value") end)
      |> Map.split(Map.values(fixed_values))
      |> fn({f, v}) -> Map.put(f, "content", v) end.()
  end

  defp business_concept_create(token, data_domain_id,  attrs) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{"business_concept" => attrs} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
        HTTPoison.post!(data_domain_business_concept_url(@endpoint, :create, data_domain_id), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp business_concept_update(token, business_concept_id, attrs) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{"business_concept" => attrs} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
        HTTPoison.put!(business_concept_url(@endpoint, :update, business_concept_id), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp business_concept_send_for_approval(token, business_concept_id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: _resp} =
        HTTPoison.put!(business_concept_url(@endpoint, :send_for_approval, business_concept_id), body, headers, [])
    {:ok, status_code}
  end

  defp business_concept_reject(token, business_concept_id, reject_reason) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{reject_reason: reject_reason} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: _resp} =
        HTTPoison.put!(business_concept_url(@endpoint, :reject, business_concept_id), body, headers, [])
    {:ok, status_code}
  end

  defp business_concept_publish(token, business_concept_id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: _resp} =
        HTTPoison.put!(business_concept_url(@endpoint, :publish, business_concept_id), body, headers, [])
    {:ok, status_code}
  end

  defp business_concept_show(token, id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(business_concept_url(@endpoint, :show, id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp business_concept_list(token) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(business_concept_url(@endpoint, :index), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def business_concept_by_name(token, business_concept_name) do
    {:ok, _status_code, json_resp} = business_concept_list(token)
    Enum.find(json_resp["data"], fn(business_concept) -> business_concept["name"] == business_concept_name end)
  end

  def business_concept_by_name_and_type(token, business_concept_name, business_concept_type) do
    {:ok, _status_code, json_resp} = business_concept_list(token)
    Enum.find(json_resp["data"],
     fn(business_concept) -> business_concept["name"] == business_concept_name
     and  business_concept["type"] == business_concept_type end)
  end

  def business_concept_by_version_name_and_type(token, business_concept_version,
                                                      business_concept_name,
                                                      business_concept_type) do
    {:ok, _status_code, json_resp} = business_concept_list(token)
    Enum.find(json_resp["data"],
     fn(business_concept) ->
       business_concept["version"] == business_concept_version &&
       business_concept["name"] == business_concept_name &&
       business_concept["type"] == business_concept_type
     end)
  end

end
