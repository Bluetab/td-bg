defmodule TrueBG.BusinessConceptTest do
  use Cabbage.Feature, async: false, file: "business_concept.feature"
  use TrueBGWeb.ConnCase

  # import TrueBGWeb.Router.Helpers
  import TrueBGWeb.ResponseCode
  import TrueBGWeb.User, only: :functions
  import TrueBGWeb.Taxonomy, only: :functions
  import TrueBGWeb.Authentication, only: :functions

  alias Poison, as: JSON

  @endpoint TrueBGWeb.Endpoint
  @headers {"Content-type", "application/json"}

  defgiven ~r/^an existing Domain Group called "(?<domain_group_name>[^"]+)"$/,
    %{domain_group_name: domain_group_name}, state do
    token_admin = case state[:token_admin] do
                nil ->
                  {_, _, %{"token" => token}} = session_create("app-admin", "mypass")
                  token
                _ -> state[:token_admin]
              end
    {_, status_code, _json_resp} = domain_group_create(token_admin, %{name: domain_group_name})
    assert rc_created() == to_response_code(status_code)
    {:ok, Map.merge(state, %{token_admin: token_admin})}
  end

  # Scenario Outline: Creating a simple date business concept
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

  defand ~r/^an existing Business Concept type called "(?<business_concept_type>[^"]+)" with following data:$/,
          %{business_concept_type: business_concept_type, table: table},
          %{} = state do

    schema_item_fn = fn(row) ->
      name = row |> Map.get(:Field) |> String.trim
      type = row |> Map.get(:Format) |> String.trim
      max_size = row |> Map.get(:"Max Size") |> String.trim
      values = row |> Map.get(:Values) |> String.trim
      required = row |> Map.get(:Mandatory) |> String.trim
      default = row |> Map.get(:"Default Value") |> String.trim

      map = Map.new
      map = if name != "" do
        map |> Map.put(:name, name)
      else
        map
      end

      map = if type != "" do
        map |> Map.put(:type, type)
      else
        map
      end

      map = if max_size != "" do
        {max, _} = Integer.parse(max_size)
        map |> Map.put(:max_size, max)
      else
        map
      end

      map = if values != "" do
        values_ary = values
          |> String.split(",")
          |> Enum.map(&(String.trim(&1)))

        map |> Map.put(:values, values_ary)
      else
        map
      end

      map = if required !=  "" && required == "YES" do
        map |> Map.put(:required, true)
      else
        map
      end

      map = if default  != "" do
        map |> Map.put(:default, default)
      else
        map
      end

      map
    end

    schema = table |> Enum.map(schema_item_fn)

    filename = Application.get_env(:trueBG, :bc_schema_location)
    {:ok, file} = File.open filename, [:write, :utf8]
    json_schema = [{business_concept_type, schema}] |> Map.new |> JSON.encode!
    IO.binwrite file, json_schema
    File.close file

    {:ok, Map.merge(state, %{bc_type: business_concept_type})}
  end

  defand ~r/^following users exist with the indicated role in Data Domain "(?<data_domain_name>[^"]+)"$/,
          %{data_domain_name: data_domain_name, table: table}, %{token_admin: token_admin} = state do

    data_domain = get_data_domain_by_name(token_admin, data_domain_name)
    assert data_domain_name == data_domain["name"]

    create_user_and_acl_entries_fn = fn(x) ->
      user_name = x[:user]
      role_name = x[:role]
      {_, _, %{"data" => %{"id" => principal_id}}} = user_create(token_admin, %{user_name: user_name, password: user_name})
      %{"id" => role_id} = get_role_by_name(token_admin, role_name)
      acl_entry_params = %{principal_type: "user", principal_id: principal_id, resource_type: "data_domain", resource_id: data_domain["id"], role_id: role_id}
      {_, _status_code, _json_resp} = acl_entry_create(token_admin , acl_entry_params)
    end

    users = table |> Enum.map(create_user_and_acl_entries_fn)

    {:ok, Map.merge(state, %{users: users})}
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" is logged in the application with password "(?<password>[^"]+)"$/, %{user_name: user_name, password: password}, state do
    {_, status_code, %{"token" => token} = json_resp} = session_create(user_name, password)
    assert rc_created() == to_response_code(status_code)
    {:ok, Map.merge(state, %{status_code: status_code, resp: json_resp, token_admin: token, u_user_name: user_name})}
  end

  defand ~r/^(?<user_name>[^"]+) tries to create a business concept in the Data Domain "(?<data_domain_name>[^"]+)" with following data:$/,
          %{user_name: user_name, data_domain_name: data_domain_name, table: [%{Type: type, Name: name, Description: description} = content|_]},
          %{u_user_name: u_user_name, bc_type: bc_type, token_admin: token_admin} = state do

    data_domain = get_data_domain_by_name(token_admin, data_domain_name)
    assert user_name == u_user_name
    assert data_domain_name == data_domain["name"]
    assert type == bc_type

    content = content
      |> Map.delete(:Type)
      |> Map.delete(:Name)
      |> Map.delete(:Description)

    {_, status_code, %{"data" => %{"id" => id, "name" => name}}} =
      business_concept_create(token_admin, type, name, description, data_domain["id"], content)
    {:ok, Map.merge(state, %{status_code: status_code, bc_id: id, bc_name: name, token_admin: token_admin})}
  end

  defthen ~r/^the system returns a result with code (?<status_code>[^"]+)$/,
          %{status_code: status_code}, %{status_code: http_status_code} = state do
    assert status_code == to_response_code(http_status_code)
    {:ok, Map.merge(state, %{})}
  end

  defp assert_field(%{Field: "Name", Value: v0}, %{"name" => v1}), do: assert v0 == v1
  defp assert_field(%{Field: "Type", Value: v0}, %{"type" => v1}), do: assert v0 == v1
  defp assert_field(%{Field: "Description", Value: v0}, %{"description" => v1}), do: assert v0 == v1
  defp assert_field(%{Field: "Formula", Value: v0}, %{"content" => %{"Formula" => v1}}), do: assert v0 == v1
  defp assert_field(%{Field: "Format", Value: v0},  %{"content" => %{"Format" => v1}}), do: assert v0 == v1
  defp assert_field(%{Field: "List of Values", Value: v0},  %{"content" => %{"List of Values" => v1}}), do: assert v0 == v1
  defp assert_field(%{Field: "Sensitve Data", Value: v0},  %{"content" => %{"Sensitve Data" => v1}}), do: assert v0 == v1
  defp assert_field(%{Field: "Update Frequence", Value: v0},  %{"content" => %{"Update Frequence" => v1}}), do: assert v0 == v1
  defp assert_field(%{Field: "Related Area", Value: v0},  %{"content" => %{"Related Area" => v1}}), do: assert v0 == v1
  defp assert_field(%{Field: "Default Value", Value: v0},  %{"content" => %{"Default Value" => v1}}), do: assert v0 == v1
  defp assert_field(%{Field: "Additional Data", Value: v0},  %{"content" => %{"Additional Data" => v1}}), do: assert v0 == v1
  defp assert_field(%{Field: "Last Modification", Value: _v0}, %{"last_change" => _v1}), do: nil
  defp assert_field(%{Field: "Last User", Value: _v0}, %{"modifier" => _v1}), do: nil
  defp assert_field(%{Field: "Version", Value: v0}, %{"version" => v1}), do: assert Integer.parse(v0) == {v1, ""}
  defp assert_field(%{}, %{}), do: nil

  defp assert_fields([tail|head], businness_concept) do
    assert_field(tail, businness_concept)
    assert_fields(head, businness_concept)
  end
  defp assert_fields([], _businness_concept),  do: nil

  defp validate_user_is_able(user_name, bc_id, fields) do
    {_, _, %{"token" => token}} = session_create(user_name, user_name)
    {_, status_code, %{"data" => business_concept}} = businness_concept_show(token, bc_id)
    assert rc_ok() == to_response_code(status_code)
    assert_fields(fields, business_concept)
  end

  defp validate_user_is_not_able(user_name, bc_id, fields) do
    {_, _, %{"token" => token}} = session_create(user_name, user_name)
    {_, status_code, %{"data" => business_concept}} = businness_concept_show(token, bc_id)
    assert rc_ok() == to_response_code(status_code)
    assert_fields(fields, business_concept)
  end

  defand ~r/^the user list (?<users>[^"]+) are (?<able>[^"]+) to see the business concept "(?<business_concept_name>[^"]+)" with (?<business_concept_status>[^"]+) status and following data:$/,
          %{users: users, able: able, business_concept_name: business_concept_name, business_concept_status: _business_concept_status, table: fields},
          %{bc_id: bc_id, bc_name: bc_name} = state do

    assert business_concept_name == bc_name

    users_ary = users |> String.split(",") |> Enum.map(&(String.trim(&1)))
    case able do
      "able" ->
        users_ary
          |> Enum.each(fn(u) -> validate_user_is_able(u, bc_id, fields) end)
      "not able" ->
        users_ary
          |> Enum.each(fn(u) -> validate_user_is_not_able(u, bc_id, fields) end)
    end

    {:ok, Map.merge(state, %{})}
  end

  defand ~r/^if result (?<result>[^"]+) is "(?<status_code>[^"]+)", (?<user_name>[^"]+) is able to view business concept "(?<business_concept_name>[^"]+)" as a child of Data Domain "(?<data_domain_name>[^"]+)"$/,
          %{result: result, status_code: status_code, user_name: user_name, business_concept_name: business_concept_name, data_domain_name: data_domain_name},
          %{bc_id: bc_id, bc_name: bc_name, u_user_name: u_user_name, token_admin: token_admin} = state do

    data_domain = get_data_domain_by_name(token_admin, data_domain_name)
    assert business_concept_name == bc_name
    assert data_domain_name == data_domain["name"]
    assert user_name == u_user_name

    if result == status_code do
      {_, http_status_code, %{"data" => business_concept}} = businness_concept_show(token_admin, bc_id)
      assert rc_ok() == to_response_code(http_status_code)
      assert business_concept["data_domain_id"] == data_domain["id"]
      {:ok, Map.merge(state, %{business_concept: business_concept})}
    else
      {:ok, Map.merge(state, %{})}
    end
  end

  defp business_concept_create(token, type, name, description, data_domain_id, content) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{business_concept: %{type: type, name: name,
             description: description, data_domain_id: data_domain_id,
             content: content}} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
        HTTPoison.post!(business_concept_url(@endpoint, :create), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp businness_concept_show(token, id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(business_concept_url(@endpoint, :show, id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp acl_entry_create(token, acl_entry_params) do
    headers = get_header(token)
    body = %{acl_entry: acl_entry_params} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(acl_entry_url(@endpoint, :create), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

end
