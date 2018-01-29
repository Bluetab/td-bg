defmodule TrueBG.BusinessConceptTest do
  use Cabbage.Feature, async: false, file: "business_concept.feature"
  use TrueBGWeb.ConnCase

  # import TrueBGWeb.Router.Helpers
  # import TrueBGWeb.ResponseCode
  # alias TrueBG.Accounts
  # alias Poison, as: JSON
  #
  alias TrueBG.Taxonomies
  #
  # @endpoint TrueBGWeb.Endpoint
  # @headers {"Content-type", "application/json"}

  # Scenario Outline: Creating a simple date business concept

  defgiven ~r/^an existing Domain Group called "(?<name>[^"]+)"$/, %{name: name}, state do
    existing_dg = Taxonomies.get_domain_group_by_name(name)
    {_, parent_domain_group} =
      case existing_dg do
        nil ->
          Taxonomies.create_domain_group(%{name: name})
        _ ->
          {:ok, existing_dg}
      end
    {:ok, Map.merge(state, %{parent_domain_group: parent_domain_group})}
  end

  defand ~r/^an existing Domain Group called "(?<name>[^"]+)" child of Domain Group "My Parent Group"$/,
          %{name: name}, %{parent_domain_group: parent_domain_group} = state do
    {_, domain_group} = Taxonomies.create_domain_group(%{name: name, parent_id: parent_domain_group.id})
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
          %{business_concept_type: _business_concept_type, table: _table},
          %{} = state do

    #assert business_concept_type = "Business Term"

    {:ok, Map.merge(state, %{})}
  end

  #   And follwinig users exist with the indicated role in Data Domain "My Domain"
  #     | user      | role    |
  #     | watcher   | watch   |
  #     | creator   | create  |
  #     | publisher | publish |
  #     | admin     | admin   |

  defwhen ~r/^(?<user_name>[^"]+) tries to create a business concept in the Data Domain "(?<data_domain_name>[^"]+)" with following data:$/,
          %{user_name: _user_name, data_domain_name: _data_domain_name, table: _table},
          %{data_domain: _data_domain} = state do

    #assert data_domain_name = data_domain.name

    {:ok, Map.merge(state, %{})}
  end

  defthen ~r/^the system returns a result with code (?<status_code>[^"]+)$/, %{status_code: _status_code}, state do
      {:ok, Map.merge(state, %{})}
  end

  defand ~r/^the user list (?<users>[^"]+) are (?<able>[^"]+) to see the business concept "(?<business_concept_name>[^"]+)" with (?<business_concept_status>[^"]+) status and following data:$/,
          %{users: _users, able: _able, business_concept_name: business_concept_name, business_concept_status: _business_concept_status, table: _table}, state do

    assert business_concept_name == "My Date Business Term"

    {:ok, Map.merge(state, %{})}
  end

  defand ~r/^the business concept "(?<business_concept_name>[^"]+)" is a child of Data Domain "(?<data_domain_name>[^"]+)"$/,
          %{business_concept_name: business_concept_name, data_domain_name: data_domain_name}, state do
    assert business_concept_name == "My Date Business Term"
    assert data_domain_name == "My Domain"

    {:ok, Map.merge(state, %{})}
  end

  #   And the business concept "My Date Business Term" is a child of Data Domain "My Domain"

end
