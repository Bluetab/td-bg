defmodule TdBgWeb.BusinessConcept do
  @moduledoc false

  alias Poison, as: JSON
  import TdBgWeb.Router.Helpers
  import TdBgWeb.Authentication, only: :functions

  @df_cache Application.get_env(:td_bg, :df_cache)

  @endpoint TdBgWeb.Endpoint
  @headers {"Content-type", "application/json"}

  def fixed_values,
    do: %{
      "Type" => "type",
      "Name" => "name",
      "Description" => "description",
      "Status" => "status",
      "Last Modification" => "last_change_at",
      "Last User" => "last_change_by",
      "Current" => "current",
      "Version" => "version",
      "Reject Reason" => "reject_reason",
      "Modification Comments" => "mod_comments",
      "Related To" => "related_to",
      "In Progress" => "in_progress"
    }

  def create_template(type, definition) do
    attrs =
      %{}
      |> Map.put(:id, 0)
      |> Map.put(:label, type)
      |> Map.put(:name, type)
      |> Map.put(:content, definition)

    @df_cache.put_template(attrs)

    {:ok, nil, attrs}
  end

  def rm_business_concept_schema do
    File.rm(Application.get_env(:td_bg, :bc_schema_location))
  end

  def business_concept_field_values_to_api_attrs(table) do
    table
    |> Enum.reduce(%{}, fn x, acc ->
      Map.put(acc, Map.get(fixed_values(), x."Field", x."Field"), x."Value")
    end)
    |> Map.split(Map.values(fixed_values()))
    |> (fn {f, v} -> Map.put(f, "content", v) end).()
  end

  def business_concept_create(token, domain_id, attrs) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    create_attrs = case Map.has_key?(attrs, "description") do
      true ->
        description = Map.get(attrs, "description")
        Map.put(attrs, "description" , to_rich_text(description))
      false -> attrs
    end
    create_attrs = Map.put(create_attrs, "domain_id", domain_id)

    body = %{"business_concept_version" => create_attrs} |> JSON.encode!()

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(business_concept_version_url(@endpoint, :create), body, headers, [])

    {:ok, status_code, resp |> JSON.decode!()}
  end

  def business_concept_update(token, business_concept_id, attrs) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]

    attrs =
      case Map.has_key?(attrs, "description") do
        true ->
          description = Map.get(attrs, "description")
          Map.put(attrs, "description" , to_rich_text(description))
        false -> attrs
      end

    body = %{"business_concept" => attrs} |> JSON.encode!()

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.put!(
        business_concept_url(@endpoint, :update, business_concept_id),
        body,
        headers,
        []
      )

    {:ok, status_code, resp |> JSON.decode!()}
  end

  def business_concept_send_for_approval(token, business_concept_version) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{"business_concept" => %{"status" => "pending_approval"}} |> JSON.encode!()

    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.patch!(
        business_concept_business_concept_url(@endpoint, :update_status, business_concept_version |> JSON.encode!()),
        body,
        headers,
        []
      )

    {:ok, status_code}
  end

  def business_concept_version_send_for_approval(token, business_concept_version_id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{} |> JSON.encode!()

    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.post!(
        business_concept_version_business_concept_version_url(
          @endpoint,
          :send_for_approval,
          business_concept_version_id
        ),
        body,
        headers,
        []
      )

    {:ok, status_code}
  end

  def business_concept_reject(token, business_concept_id, reject_reason) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]

    body =
      %{"business_concept" => %{"status" => "rejected", "reject_reason" => reject_reason}}
      |> JSON.encode!()

    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.patch!(
        business_concept_business_concept_url(@endpoint, :update_status, business_concept_id),
        body,
        headers,
        []
      )

    {:ok, status_code}
  end

  def business_concept_version_reject(token, business_concept_version_id, reject_reason) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{"reject_reason" => reject_reason} |> JSON.encode!()

    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.post!(
        business_concept_version_business_concept_version_url(
          @endpoint,
          :reject,
          business_concept_version_id
        ),
        body,
        headers,
        []
      )

    {:ok, status_code}
  end

  def business_concept_undo_rejection(token, business_concept_id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{"business_concept" => %{"status" => "draft"}} |> JSON.encode!()

    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.patch!(
        business_concept_business_concept_url(@endpoint, :update_status, business_concept_id),
        body,
        headers,
        []
      )

    {:ok, status_code}
  end

  def business_concept_version_deprecate(token, business_concept_version_id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{} |> JSON.encode!()

    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.post!(
        business_concept_version_business_concept_version_url(
          @endpoint,
          :deprecate,
          business_concept_version_id
        ),
        body,
        headers,
        []
      )

    {:ok, status_code}
  end

  def business_concept_publish(token, business_concept_id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{"business_concept" => %{"status" => "published"}} |> JSON.encode!()

    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.patch!(
        business_concept_business_concept_url(@endpoint, :update_status, business_concept_id),
        body,
        headers,
        []
      )

    {:ok, status_code}
  end

  def business_concept_version_publish(token, business_concept_version_id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{} |> JSON.encode!()

    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.post!(
        business_concept_version_business_concept_version_url(
          @endpoint,
          :publish,
          business_concept_version_id
        ),
        body,
        headers,
        []
      )

    {:ok, status_code}
  end

  def business_concept_version(token, business_concept_id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{"business_concept" => %{"status" => "draft"}} |> JSON.encode!()

    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.patch!(
        business_concept_business_concept_url(@endpoint, :update_status, business_concept_id),
        body,
        headers,
        []
      )

    {:ok, status_code}
  end

  def business_concept_show(token, id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(business_concept_url(@endpoint, :show, id), headers, [])

    {:ok, status_code, resp |> JSON.decode!()}
  end

  def business_concept_version_delete(token, id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]

    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.delete!(business_concept_version_url(@endpoint, :delete, id), headers, [])

    {:ok, status_code}
  end

  def business_concept_version_versions(token, business_concept_version_id) do
    headers = get_header(token)

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(
        business_concept_version_business_concept_version_url(@endpoint, :versions, business_concept_version_id),
        headers,
        []
      )

    {:ok, status_code, resp |> JSON.decode!()}
  end

  def business_concept_list(token) do
    headers = get_header(token)

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(business_concept_version_url(@endpoint, :index), headers, [])

    {:ok, status_code, resp |> JSON.decode!()}
  end

  def business_concept_search(token, filter) do
    headers = get_header(token)

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(business_concept_url(@endpoint, :search), headers, filter)

    {:ok, status_code, resp |> JSON.decode!()}
  end

  def business_concept_by_name(token, business_concept_name) do
    {:ok, _status_code, json_resp} = business_concept_list(token)

    Enum.find(
      json_resp["data"],
      fn business_concept ->
        business_concept["name"] == business_concept_name && business_concept["current"]
      end
    )
  end

  def business_concept_by_name_and_type(token, business_concept_name, business_concept_type) do
    {:ok, _status_code, json_resp} = business_concept_list(token)

    Enum.find(
      json_resp["data"],
      fn business_concept ->
        business_concept["name"] == business_concept_name &&
          business_concept["type"] == business_concept_type && business_concept["current"]
      end
    )
  end

  def business_concept_by_version_name_and_type(
        token,
        business_concept_version,
        business_concept_name,
        business_concept_type
      ) do
    {:ok, _status_code, json_resp} = business_concept_list(token)

    Enum.find(
      json_resp["data"],
      fn business_concept ->
        business_concept["version"] == business_concept_version &&
          business_concept["name"] == business_concept_name &&
          business_concept["type"] == business_concept_type
      end
    )
  end

  def business_concept_version_show(token, id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(business_concept_version_url(@endpoint, :show, id), headers, [])

    {:ok, status_code, resp |> JSON.decode!()}
  end

  def business_concept_version_upload(token, business_concepts) do
    headers = get_header(token)

    form =
      {:multipart,
       [
         {"file", business_concepts,
          {"form-data", [{"name", "business_concepts"}, {"filename", "business_concepts.csv"}]},
          [{"Content-Type", "text/csv"}]},
       ]}

    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.post!(business_concept_version_url(@endpoint, :upload), form, headers)

    {:ok, status_code}
  end

  def business_concept_alias_create(token, business_concept_id, attrs) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{"business_concept_alias" => attrs} |> JSON.encode!()

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(
        business_concept_business_concept_alias_url(@endpoint, :create, business_concept_id),
        body,
        headers,
        []
      )

    {:ok, status_code, resp |> JSON.decode!()}
  end

  def business_concept_alias_list(token, business_concept_id) do
    headers = get_header(token)

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(
        business_concept_business_concept_alias_url(@endpoint, :index, business_concept_id),
        headers,
        []
      )

    {:ok, status_code, resp |> JSON.decode!()}
  end

  def business_concept_alias_delete(token, id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]

    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.delete!(business_concept_alias_url(@endpoint, :delete, id), headers, [])

    {:ok, status_code}
  end

  def business_concept_alias_by_name(token, business_concept_id, business_concept_alias) do
    {:ok, _status_code, json_resp} = business_concept_alias_list(token, business_concept_id)

    Enum.find(
      json_resp["data"],
      fn alias_item -> alias_item["name"] == business_concept_alias end
    )
  end

  def business_concept_list_with_status(token, status) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(business_concept_url(@endpoint, :index_status, status), headers, [])

    {:ok, status_code, resp |> JSON.decode!()}
  end

  def to_rich_text(nil), do: %{}
  def to_rich_text(""),  do: %{}
  def to_rich_text(text) do
    %{document: %{nodes: [%{object: "block",
      type: "paragraph",
      nodes: [%{object: "text",
                leaves: [%{text: text}
             ]}]}]}}
  end

  def to_plain_text(text) do
    text
    |> Map.get("document")
    |> Map.get("nodes")
    |> Enum.at(0)
    |> Map.get("nodes")
    |> Enum.at(0)
    |> Map.get("leaves")
    |> Enum.at(0)
    |> Map.get("text")
  end

end
