defmodule TdBg.TaxonomyErrorsTest do
  use Cabbage.Feature, async: false, file: "taxonomies/taxonomy_errors.feature"
  use TdBgWeb.FeatureCase

  import TdBgWeb.ResponseCode
  import TdBgWeb.Taxonomy
  import TdBgWeb.Authentication, only: :functions
  import TdBgWeb.BusinessConcept

  alias Jason, as: JSON
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.Permissions.MockPermissionResolver
  alias TdBgWeb.ApiServices.MockTdAuditService
  alias TdBgWeb.ApiServices.MockTdAuthService

  import_steps(TdBg.BusinessConceptSteps)
  import_steps(TdBg.DomainSteps)
  import_steps(TdBg.ResultSteps)

  import TdBg.ResultSteps
  import TdBg.BusinessConceptSteps

  setup_all do
    start_supervised(MockTdAuthService)
    start_supervised(MockTdAuditService)
    start_supervised(MockPermissionResolver)
    :ok
  end

  defwhen ~r/^user "(?<user_name>[^"]+)" tries to create a Domain as child of Domain "(?<domain_name>[^"]+)" with following data:$/,
          %{
            user_name: user_name,
            domain_name: domain_name,
            table: [%{name: name, description: description}]
          },
          state do
    parent = get_domain_by_name(state[:token_admin], domain_name)
    assert parent["name"] == domain_name
    token = build_user_token(user_name)

    {_, status_code, json_resp} =
      domain_create(token, %{name: name, description: description, domain_id: parent["id"]})

    {:ok, Map.merge(state, %{status_code: status_code, json_resp: json_resp})}
  end

  defand ~r/^the system returns a response with following data:$/,
         %{doc_string: json_string},
         state do
    actual_data = state[:json_resp]
    expected_data = json_string |> JSON.decode!()
    assert JSONDiff.diff(actual_data, expected_data) == []
  end

  defwhen ~r/^user "(?<username>[^"]+)" tries to update a Domain called "(?<domain_name_child>[^"]+)" child of Domain "(?<domain_name_parent>[^"]+)" with following data:$/,
          %{
            username: username,
            domain_name_child: domain_name_child,
            domain_name_parent: domain_name_parent,
            table: [%{name: name, description: description}]
          },
          state do
    token_admin = build_user_token(username, is_admin: true)
    domain_parent = get_domain_by_name(token_admin, domain_name_parent)

    domain_child =
      get_domain_by_name_and_parent(token_admin, domain_name_child, domain_parent["id"])

    {_, status_code, json_resp} =
      domain_update(token_admin, domain_child["id"], %{name: name, description: description})

    {:ok,
     Map.merge(state, %{token_admin: token_admin, status_code: status_code, json_resp: json_resp})}
  end

  defwhen ~r/^user "(?<username>[^"]+)" tries to create a Domain with following data:$/,
          %{username: username, table: [%{name: name, description: description}]},
          state do
    token_admin = build_user_token(username, is_admin: true)

    {_, status_code, json_resp} =
      domain_create(token_admin, %{name: name, description: description})

    {:ok,
     Map.merge(state, %{token_admin: token_admin, status_code: status_code, json_resp: json_resp})}
  end
end
