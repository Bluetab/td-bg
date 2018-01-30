defmodule TrueBG.BusinessConceptTest do
  use Cabbage.Feature, async: false, file: "business_concept.feature"
  use TrueBGWeb.ConnCase

  # import TrueBGWeb.Router.Helpers
  import TrueBGWeb.ResponseCode
  import TrueBGWeb.Taxonomy, only: :functions
  import TrueBGWeb.Authentication, only: :functions

  import_feature TrueBGWeb.GlobalFeatures

  alias Poison, as: JSON
  alias TrueBG.Accounts
  alias TrueBG.Accounts.User
  alias TrueBG.Taxonomies

  @endpoint TrueBGWeb.Endpoint
  @headers {"Content-type", "application/json"}

  # Scenario Outline: Creating a simple date business concept
  defand ~r/^an existing Domain Group called "(?<child_domain_group_name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)"$/,
          %{child_domain_group_name: child_domain_group_name, domain_group_name: domain_group_name}, state do

    token = state[:token_admin]
    parent = get_domain_group_by_name(token, domain_group_name)
    {_, domain_group} = Taxonomies.create_domain_group(%{name: child_domain_group_name, parent_id: parent["id"]})
    {:ok, Map.merge(state, %{domain_group: domain_group})}
  end

  defand ~r/^an existing Data Domain called "(?<name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)"$/,
          %{name: name, domain_group_name: domain_group_name}, %{domain_group: domain_group} = state do
    assert domain_group.name == domain_group_name
    existing_dd = Taxonomies.get_data_domain_by_name(name)
    {_, data_domain} =
      case existing_dd do
        nil ->
          Taxonomies.create_data_domain(%{name: name, domain_group_id: domain_group.id})
        _ ->
          {:ok, existing_dd}
      end
    assert data_domain.domain_group_id == domain_group.id
    {:ok, Map.merge(state, %{data_domain: data_domain})}
  end

  defand ~r/^follwinig users exist with the indicated role in Data Domain "(?<data_domain_name>[^"]+)"$/,
          %{data_domain_name: data_domain_name, table: table},
          %{data_domain: data_domain} = state do

    assert data_domain_name = data_domain.name
    {:ok, Map.merge(state, %{})}
  end

  defand ~r/^an existing Business Concept type called "(?<business_concept_type>[^"]+)" with following data:$/,
          %{business_concept_type: business_concept_type, table: _table},
          %{} = state do

    {:ok, Map.merge(state, %{bc_type: business_concept_type})}
  end

  defand ~r/^follwinig users exist with the indicated role in Data Domain "(?<data_domain_name>[^"]+)"$/,
          %{data_domain_name: data_domain_name, table: table},
          %{data_domain: data_domain} = state do
    assert data_domain_name == data_domain.name

    create_user_fn = fn(x) ->
      user_name = x[:user]
      {_, %User{} = user} = Accounts.create_user(%{user_name: user_name, password: user_name})
      user
    end

    users = table |> Enum.map(create_user_fn)

    {:ok, Map.merge(state, %{users: users})}
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" is logged in the application with password "(?<password>[^"]+)"$/, %{user_name: user_name, password: password}, state do
    {_, status_code, %{"token" => token} = json_resp} = session_create(user_name, password)
    assert rc_created() == to_response_code(status_code)
    {:ok, Map.merge(state, %{status_code: status_code, resp: json_resp, token: token, u_user_name: user_name})}
  end

  defand ~r/^(?<user_name>[^"]+) tries to create a business concept in the Data Domain "(?<data_domain_name>[^"]+)" with following data:$/,
          %{user_name: user_name, data_domain_name: data_domain_name, table: [%{Type: type, Name: name, Description: description} = content|_]},
          %{u_user_name: u_user_name, bc_type: bc_type, data_domain: data_domain, token: token} = state do

    assert user_name == u_user_name
    assert data_domain_name == data_domain.name
    assert type == bc_type

    content = content
      |> Map.delete(:Type)
      |> Map.delete(:Name)
      |> Map.delete(:Description)

    {_, status_code, %{"data" => %{"id" => id, "name" => name}}} =
      business_concept_create(token, type, name, description, data_domain.id, content)
    {:ok, Map.merge(state, %{status_code: status_code, bc_id: id, bc_name: name, token: token})}
  end

  defand ~r/^the user list (?<users>[^"]+) are (?<able>[^"]+) to see the business concept "(?<business_concept_name>[^"]+)" with (?<business_concept_status>[^"]+) status and following data:$/,
          %{users: _users, able: _able, business_concept_name: business_concept_name, business_concept_status: _business_concept_status, table: _table},
          %{bc_name: bc_name} = state do

    assert business_concept_name == bc_name
    {:ok, Map.merge(state, %{})}
  end

  defand ~r/^if result (?<result>[^"]+) is "(?<status_code>[^"]+)", (?<user_name>[^"]+) is able to view business concept "(?<business_concept_name>[^"]+)" as a child of Data Domain "(?<data_domain_name>[^"]+)"$/,
          %{result: result, status_code: status_code, user_name: user_name, business_concept_name: business_concept_name, data_domain_name: data_domain_name},
          %{bc_id: bc_id, bc_name: bc_name, u_user_name: u_user_name, data_domain: data_domain, token: token} = state do

    assert business_concept_name == bc_name
    assert data_domain_name == data_domain.name
    assert user_name == u_user_name

    if result == status_code do
      {_, http_status_code, %{"data" => business_concept}} = businness_concept_show(token, bc_id)
      assert rc_ok() == to_response_code(http_status_code)
      assert business_concept["data_domain_id"] == data_domain.id
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

end
