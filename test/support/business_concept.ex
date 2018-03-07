defmodule TdBGWeb.BusinessConcept do
  @moduledoc false

  alias Poison, as: JSON
  import TdBGWeb.Router.Helpers
  import TdBGWeb.Authentication, only: :functions

  @endpoint TdBGWeb.Endpoint
  @headers {"Content-type", "application/json"}
  @fixed_values %{"Type" => "type",
                  "Name" => "name",
                  "Description" => "description",
                  "Status" => "status",
                  "Last Modification" => "last_change_at",
                  "Last User" => "last_change_by",
                  "Version" => "version",
                  "Reject Reason" => "reject_reason",
                  "Modification Comments" => "mod_comments"
                  }

  def business_concept_field_values_to_api_attrs(table) do
    table
      |> Enum.reduce(%{}, fn(x, acc) -> Map.put(acc, Map.get(@fixed_values, x."Field", x."Field"), x."Value") end)
      |> Map.split(Map.values(@fixed_values))
      |> fn({f, v}) -> Map.put(f, "content", v) end.()
  end

  def business_concept_create(token, data_domain_id,  attrs) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{"business_concept" => attrs} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
        HTTPoison.post!(data_domain_business_concept_url(@endpoint, :create, data_domain_id), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def business_concept_update(token, business_concept_id, attrs) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{"business_concept" => attrs} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
        HTTPoison.put!(business_concept_url(@endpoint, :update, business_concept_id), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def business_concept_send_for_approval(token, business_concept_id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{"status" => "pending_approval"} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: _resp} =
        HTTPoison.patch!(business_concept_business_concept_status_url(@endpoint, :update, business_concept_id), body, headers, [])
    {:ok, status_code}
  end

  def business_concept_reject(token, business_concept_id, reject_reason) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{"status" => "rejected", "reject_reason" => reject_reason} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: _resp} =
        HTTPoison.patch!(business_concept_business_concept_status_url(@endpoint, :update, business_concept_id), body, headers, [])
    {:ok, status_code}
  end

  def business_concept_publish(token, business_concept_id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{"status" => "published"} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: _resp} =
        HTTPoison.patch!(business_concept_business_concept_status_url(@endpoint, :update, business_concept_id), body, headers, [])
    {:ok, status_code}
  end

  def business_concept_show(token, id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(business_concept_url(@endpoint, :show, id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def business_concept_delete(token, id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.delete!(business_concept_url(@endpoint, :delete, id), headers, [])
    {:ok, status_code}
  end

  def business_concept_list(token) do
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

  def business_concept_version_show(token, id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(business_concept_version_url(@endpoint, :show, id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  def business_concept_version_create(token, business_concept_id, attrs) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{"business_concept" => attrs} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
        HTTPoison.post!(business_concept_business_concept_version_url(@endpoint, :create, business_concept_id), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

end
