defmodule TdBg.DomainSteps do
  @moduledoc false
  use Cabbage.Feature
  use ExUnit.CaseTemplate

  defgiven ~r/^an existing Domain called "(?<domain_name>[^"]+)"$/,
           %{domain_name: domain_name},
           state do
    token_admin =
      case state[:token_admin] do
        nil -> build_user_token("app-admin")
        _ -> state[:token_admin]
      end

    {_, status_code, _json_resp} =
      domain_create(token_admin, %{name: domain_name, external_id: domain_name})

    assert rc_created() == to_response_code(status_code)
    {:ok, Map.merge(state, %{token_admin: token_admin})}
  end

  defgiven ~r/^an existing Domain called "(?<domain_name>[^"]+)" with following data:$/,
           %{domain_name: name, table: [%{Description: description}]},
           state do
    token_admin = build_user_token("app-admin")
    state = Map.merge(state, %{token_admin: token_admin})

    {:ok, status_code, json_resp} =
      domain_create(token_admin, %{name: name, external_id: name, description: description})

    assert rc_created() == to_response_code(status_code)
    domain = json_resp["data"]
    assert domain["description"] == description
    {:ok, state}
  end

  defgiven ~r/^an existing Domain called "(?<child_domain_name>[^"]+)" child of Domain "(?<domain_name>[^"]+)"$/,
           %{child_domain_name: child_domain_name, domain_name: domain_name},
           %{token_admin: token_admin} = _state do
    parent = get_domain_by_name(token_admin, domain_name)

    {_, _status_code, _json_resp} =
      domain_create(token_admin, %{
        name: child_domain_name,
        external_id: child_domain_name,
        parent_id: parent["id"]
      })
  end

  defgiven ~r/^an existing Domain called "(?<name>[^"]+)" child of Domain "(?<domain_name>[^"]+)" with following data:$/,
           %{name: name, domain_name: domain_name, table: [%{Description: description}]},
           state do
    domain_info = get_domain_by_name(state[:token_admin], domain_name)

    {:ok, status_code, json_resp} =
      domain_create(state[:token_admin], %{
        name: name,
        external_id: name,
        description: description,
        parent_id: domain_info["id"]
      })

    assert rc_created() == to_response_code(status_code)
    assert json_resp["data"]["parent_id"] == domain_info["id"]
    {:ok, state}
  end
end
