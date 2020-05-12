defmodule TdBg.TaxonomyTest do
  use Cabbage.Feature, async: false, file: "taxonomies/taxonomy.feature"
  use TdBgWeb.FeatureCase

  import TdBgWeb.AclEntry, only: :functions
  import TdBgWeb.Authentication, only: :functions
  import TdBgWeb.BusinessConcept
  import TdBgWeb.ResponseCode
  import TdBgWeb.Taxonomy
  import TdBgWeb.User, only: :functions

  alias TdBg.Cache.ConceptLoader
  alias TdBg.Cache.DomainLoader
  alias TdBg.Permissions.MockPermissionResolver
  alias TdBg.Search.IndexWorker
  alias TdBgWeb.ApiServices.MockTdAuditService
  alias TdBgWeb.ApiServices.MockTdAuthService

  import_steps(TdBg.BusinessConceptSteps)
  import_steps(TdBg.DomainSteps)
  import_steps(TdBg.ResultSteps)
  import_steps(TdBg.UsersSteps)

  import TdBg.ResultSteps
  import TdBg.BusinessConceptSteps

  setup_all do
    start_supervised(ConceptLoader)
    start_supervised(DomainLoader)
    start_supervised(IndexWorker)
    start_supervised(MockPermissionResolver)
    start_supervised(MockTdAuditService)
    start_supervised(MockTdAuthService)
    :ok
  end

  # credo:disable-for-next-line Credo.Check.Readability.MaxLineLength
  defand ~r/^if result (?<actual_result>[^"]+) is "(?<expected_result>[^"]+)", user "(?<user_name>[^"]+)" is able to see the Domain "(?<domain_name>[^"]+)" with following data:$/,
         %{
           actual_result: actual_result,
           expected_result: expected_result,
           user_name: user_name,
           domain_name: domain_name,
           table: [%{Description: description}]
         },
         state do
    if actual_result == expected_result do
      token = build_user_token(user_name)
      domain_info = get_domain_by_name(token, domain_name)
      assert domain_name == domain_info["name"]
      {:ok, status_code, json_resp} = domain_show(token, domain_info["id"])
      assert rc_ok() == to_response_code(status_code)
      domain = json_resp["data"]
      assert domain_name == domain["name"]
      assert description == domain["description"]
      {:ok, %{state | status_code: nil}}
    end
  end

  # credo:disable-for-next-line Credo.Check.Readability.MaxLineLength
  defand ~r/^if result (?<actual_result>[^"]+) is not "(?<expected_result>[^"]+)", user "(?<user_name>[^"]+)" is able to see the Domain "(?<domain_name>[^"]+)" with following data:$/,
         %{
           actual_result: actual_result,
           expected_result: expected_result,
           user_name: user_name,
           domain_name: domain_name,
           table: [%{Description: description}]
         },
         state do
    if actual_result != expected_result do
      token = build_user_token(user_name)
      domain_info = get_domain_by_name(token, domain_name)
      assert domain_name == domain_info["name"]
      {:ok, status_code, json_resp} = domain_show(token, domain_info["id"])
      assert rc_ok() == to_response_code(status_code)
      domain = json_resp["data"]
      assert domain_name == domain["name"]
      assert description == domain["description"]
      {:ok, %{state | status_code: nil}}
    end
  end

  # And if result <result> is "Created", Domain "My Data Domain" is a child of Domain "My Group"
  defand ~r/^if result (?<actual_result>[^"]+) is "(?<expected_result>[^"]+)", Domain "(?<domain_name_child>[^"]+)" is a child of Domain "(?<domain_name_parent>[^"]+)"$/,
         %{
           actual_result: actual_result,
           expected_result: expected_result,
           domain_name_child: domain_name_child,
           domain_name_parent: domain_name_parent
         },
         state do
    if actual_result == expected_result do
      domain_info_child = get_domain_by_name(state[:token_admin], domain_name_child)
      domain_info_parent = get_domain_by_name(state[:token_admin], domain_name_parent)
      assert domain_info_child["parent_id"] == domain_info_parent["id"]
    end
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to create a Domain with the name "(?<new_domain_group_name>[^"]+)" as child of Domain "(?<domain_group_name>[^"]+)" with following data:$/,
          %{
            user_name: user_name,
            new_domain_group_name: new_domain_group_name,
            domain_group_name: domain_group_name,
            table: [%{Description: description}]
          },
          %{token_admin: token_admin} = state do
    parent = get_domain_by_name(token_admin, domain_group_name)
    assert parent["name"] == domain_group_name

    token =
      case Map.get(state, :token) do
        nil -> build_user_token(user_name)
        t -> t
      end

    {_, status_code, _json_resp} =
      domain_create(token, %{
        name: new_domain_group_name,
        description: description,
        parent_id: parent["id"]
      })

    {:ok, Map.merge(state, %{status_code: status_code})}
  end

  defand ~r/^if result (?<actual_result>[^"]+) is "(?<expected_result>[^"]+)", user "(?<user_name>[^"]+)" is able to see the Domain "(?<domain_group_name>[^"]+)" with following data:$/,
         %{
           actual_result: actual_result,
           expected_result: expected_result,
           user_name: user_name,
           domain_group_name: domain_group_name,
           table: [%{Description: description}]
         },
         state do
    if actual_result == expected_result do
      token =
        case Map.get(state, :token) do
          nil -> build_user_token(user_name)
          t -> t
        end

      domain_group_info = get_domain_by_name(token, domain_group_name)
      assert domain_group_name == domain_group_info["name"]
      {:ok, status_code, json_resp} = domain_show(token, domain_group_info["id"])
      assert rc_ok() == to_response_code(status_code)
      domain = json_resp["data"]
      assert domain_group_name == domain["name"]
      assert description == domain["description"]
      {:ok, %{state | status_code: nil}}
    end
  end

  defand ~r/^if result (?<actual_result>[^"]+) is not "(?<expected_result>[^"]+)", user "(?<user_name>[^"]+)" is able to see the Domain "(?<domain_group_name>[^"]+)" with following data:$/,
         %{
           actual_result: actual_result,
           expected_result: expected_result,
           user_name: user_name,
           domain_group_name: domain_group_name,
           table: [%{Description: description}]
         },
         state do
    if actual_result != expected_result do
      token =
        case Map.get(state, :token) do
          nil -> build_user_token(user_name)
          t -> t
        end

      domain_group_info = get_domain_by_name(token, domain_group_name)
      assert domain_group_name == domain_group_info["name"]
      {:ok, status_code, json_resp} = domain_show(token, domain_group_info["id"])
      assert rc_ok() == to_response_code(status_code)
      domain = json_resp["data"]
      assert domain_group_name == domain["name"]
      assert description == domain["description"]
      {:ok, %{state | status_code: nil}}
    end
  end

  defand ~r/^if result (?<actual_result>[^"]+) is "(?<expected_result>[^"]+)", Domain "(?<domain_group_name>[^"]+)" is a child of Domain "(?<parent_domain_group_name>[^"]+)"$/,
         %{
           actual_result: actual_result,
           expected_result: expected_result,
           domain_group_name: domain_group_name,
           parent_domain_group_name: parent_domain_group_name
         },
         state do
    if actual_result == expected_result do
      domain_group_info = get_domain_by_name(state[:token_admin], domain_group_name)
      parent_domain_group_info = get_domain_by_name(state[:token_admin], parent_domain_group_name)
      assert domain_group_info["parent_id"] == parent_domain_group_info["id"]
    end
  end

  defand ~r/^user "(?<user_name>[^"]+)" tries to modify a Domain with the name "(?<domain_group_name>[^"]+)" introducing following data:$/,
         %{
           user_name: user_name,
           domain_group_name: domain_group_name,
           table: [%{Description: description}]
         },
         state do
    token = get_user_token(user_name)
    domain = get_domain_by_name(token, domain_group_name)

    {_, status_code, _json_resp} =
      domain_group_update(token, domain["id"], %{
        name: domain_group_name,
        description: description
      })

    {:ok, Map.merge(state, %{status_code: status_code, token: token})}
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to modify a Domain with the name "(?<domain_name>[^"]+)" introducing following data:$/,
          %{user_name: user_name, domain_name: domain_name, table: [%{Description: description}]},
          state do
    token = get_user_token(user_name)
    domain_info = get_domain_by_name(token, domain_name)

    {:ok, status_code, _json_resp} =
      domain_update(token, domain_info["id"], %{name: domain_name, description: description})

    {:ok, Map.merge(state, %{status_code: status_code, token: token})}
  end

  defand ~r/^if result (?<actual_result>[^"]+) is "(?<expected_result>[^"]+)", Domain "(?<domain_name_child>[^"]+)" is a child of Domain "(?<domain_name_parent>[^"]+)"$/,
         %{
           actual_result: actual_result,
           expected_result: expected_result,
           domain_name_child: domain_name_child,
           domain_name_parent: domain_name_parent
         },
         state do
    if actual_result == expected_result do
      domain_info_child = get_domain_by_name(state[:token_admin], domain_name_child)
      domain_info_parent = get_domain_by_name(state[:token_admin], domain_name_parent)
      assert domain_info_child["parent_id"] == domain_info_parent["id"]
    end
  end

  defand ~r/^if result (?<actual_result>[^"]+) is "(?<expected_result>[^"]+)", Domain "(?<child_name>[^"]+)" does not exist as child of Domain "(?<parent_name>[^"]+)"$/,
         %{
           actual_result: actual_result,
           expected_result: expected_result,
           child_name: child_name,
           parent_name: parent_name
         },
         _state do
    if actual_result == expected_result do
      token = get_user_token("app-admin")
      parent = get_domain_by_name(token, parent_name)
      child = get_domain_group_by_name_and_parent(token, child_name, parent["id"])
      assert !child
    end
  end

  defand ~r/^if result (?<actual_result>[^"]+) is not "(?<expected_result>[^"]+)", Domain "(?<domain_group_name>[^"]+)" is a child of Domain "(?<parent_domain_group_name>[^"]+)"$/,
         %{
           actual_result: actual_result,
           expected_result: expected_result,
           domain_group_name: domain_group_name,
           parent_domain_group_name: parent_domain_group_name
         },
         state do
    if actual_result != expected_result do
      domain_group_info = get_domain_by_name(state[:token_admin], domain_group_name)
      parent_domain_group_info = get_domain_by_name(state[:token_admin], parent_domain_group_name)
      assert domain_group_info["parent_id"] == parent_domain_group_info["id"]
    end
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to delete a Domain with the name "(?<domain_name>[^"]+)"$/,
          %{user_name: user_name, domain_name: domain_name},
          state do
    token = get_user_token(user_name)
    domain_info = get_domain_by_name(token, domain_name)
    {:ok, status_code, json_resp} = domain_delete(token, domain_info["id"])
    {:ok, Map.merge(state, %{status_code: status_code, json_resp: json_resp})}
  end

  defand ~r/^if result (?<actual_result>[^"]+) is "(?<expected_result>[^"]+)", Domain "(?<domain_name>[^"]+)" does not exist as child of Domain "(?<domain_group_name>[^"]+)"$/,
         %{
           actual_result: actual_result,
           expected_result: expected_result,
           domain_name: domain_name,
           domain_group_name: domain_group_name
         },
         _state do
    if actual_result == expected_result do
      token = get_user_token("app-admin")
      domain = get_domain_by_name(token, domain_group_name)
      domain = get_domain_by_name_and_parent(token, domain_name, domain["id"])
      assert !domain
    end
  end

  defand ~r/^if result (?<actual_result>[^"]+) is not "(?<expected_result>[^"]+)", Domain "(?<domain_name_child>[^"]+)" is a child of Domain "(?<domain_name_parent>[^"]+)"$/,
         %{
           actual_result: actual_result,
           expected_result: expected_result,
           domain_name_child: domain_name_child,
           domain_name_parent: domain_name_parent
         },
         state do
    if actual_result != expected_result do
      domain_info_parent = get_domain_by_name(state[:token_admin], domain_name_parent)
      domain_info_child = get_domain_by_name(state[:token_admin], domain_name_child)
      assert domain_info_child["parent_id"] == domain_info_parent["id"]
    end
  end

  defand ~r/^a error message with key "(?<key>[^"]+)" and value "(?<value>[^"]+)" is returned$/,
         %{key: key, value: value},
         state do
    state
    |> Map.get(:json_resp, %{})
    |> Map.get("errors", %{})
    |> Map.get(key, [])
    |> Enum.member?(value)
    |> assert()
  end
end
