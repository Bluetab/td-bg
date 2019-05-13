defmodule TdBgWeb.BusinessConcept do
  @moduledoc false

  alias Poison, as: JSON
  alias TdBgWeb.Router.Helpers, as: Routes
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
      |> Map.put(:scope, "test")
      |> Map.put(:content, definition)

    @df_cache.put_template(attrs)

    {:ok, nil, attrs}
  end

  def business_concept_field_values_to_api_attrs(table) do
    table
    |> Enum.reduce(%{}, fn x, acc ->
      Map.put(acc, Map.get(fixed_values(), x."Field", x."Field"), x."Value")
    end)
    |> Map.split(Map.values(fixed_values()))
    |> (fn {f, v} -> Map.put(f, "content", v) end).()
  end

  def business_concept_version_create(token, domain_id, attrs) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]

    create_attrs =
      case Map.has_key?(attrs, "description") do
        true ->
          description = Map.get(attrs, "description")
          Map.put(attrs, "description", to_rich_text(description))

        false ->
          attrs
      end

    create_attrs = Map.put(create_attrs, "domain_id", domain_id)

    body = %{"business_concept_version" => create_attrs} |> JSON.encode!()

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(Routes.business_concept_version_url(@endpoint, :create), body, headers, [])

    {:ok, status_code, resp |> JSON.decode!()}
  end

  def business_concept_version_update(token, business_concept_version_id, attrs) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]

    attrs =
      case Map.has_key?(attrs, "description") do
        true ->
          description = Map.get(attrs, "description")
          Map.put(attrs, "description", to_rich_text(description))

        false ->
          attrs
      end

    body = %{"business_concept_version" => attrs} |> JSON.encode!()

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.put!(
        Routes.business_concept_version_url(@endpoint, :update, business_concept_version_id),
        body,
        headers,
        []
      )

    {:ok, status_code, resp |> JSON.decode!()}
  end

  def business_concept_version_show(token, id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(Routes.business_concept_version_url(@endpoint, :show, id), headers, [])

    {:ok, status_code, resp |> JSON.decode!()}
  end

  def business_concept_version_delete(token, id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]

    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.delete!(Routes.business_concept_version_url(@endpoint, :delete, id), headers, [])

    {:ok, status_code}
  end

  def business_concept_version_versions(token, business_concept_version_id) do
    headers = get_header(token)

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(
        Routes.business_concept_version_business_concept_version_url(
          @endpoint,
          :versions,
          business_concept_version_id
        ),
        headers,
        []
      )

    {:ok, status_code, resp |> JSON.decode!()}
  end

  def business_concept_version_list(token) do
    headers = get_header(token)

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(Routes.business_concept_version_url(@endpoint, :index), headers, [])

    {:ok, status_code, resp |> JSON.decode!()}
  end

  def business_concept_version_send_for_approval(token, business_concept_version_id) do
    business_concept_version_workflow(token, business_concept_version_id, :send_for_approval)
  end

  def business_concept_version_redraft(token, business_concept_version_id) do
    business_concept_version_workflow(token, business_concept_version_id, :undo_rejection)
  end

  def business_concept_version_reject(token, business_concept_version_id, reject_reason) do
    body = %{"reject_reason" => reject_reason} |> JSON.encode!()
    business_concept_version_workflow(token, business_concept_version_id, :reject, body)
  end

  def business_concept_version_deprecate(token, business_concept_version_id) do
    business_concept_version_workflow(token, business_concept_version_id, :deprecate)
  end

  def business_concept_version_publish(token, business_concept_version_id) do
    business_concept_version_workflow(token, business_concept_version_id, :publish)
  end

  def business_concept_new_version(token, business_concept_version_id) do
    business_concept_version_workflow(token, business_concept_version_id, :version)
  end

  defp business_concept_version_workflow(token, business_concept_version_id, action, body \\ "") do
    headers = [@headers, {"authorization", "Bearer #{token}"}]

    %HTTPoison.Response{status_code: status_code, body: body} =
      HTTPoison.post!(
        Routes.business_concept_version_business_concept_version_url(
          @endpoint,
          action,
          business_concept_version_id
        ),
        body,
        headers,
        []
      )

    {:ok, status_code, JSON.decode!(body)}
  end

  def business_concept_version_by_name(token, business_concept_name) do
    {:ok, _status_code, json_resp} = business_concept_version_list(token)

    Enum.find(
      json_resp["data"],
      fn business_concept ->
        business_concept["name"] == business_concept_name && business_concept["current"]
      end
    )
  end

  def business_concept_version_by_name_and_type(token, name, type) do
    {:ok, _status_code, json_resp} = business_concept_version_list(token)

    Enum.find(
      json_resp["data"],
      fn business_concept_version ->
        business_concept_version["name"] == name &&
          business_concept_version["type"] == type && business_concept_version["current"]
      end
    )
  end

  def business_concept_by_version_name_and_type(
        token,
        version,
        name,
        type
      ) do
    {:ok, _status_code, json_resp} = business_concept_version_list(token)

    Enum.find(
      json_resp["data"],
      fn business_concept_version ->
        business_concept_version["version"] == version &&
          business_concept_version["name"] == name &&
          business_concept_version["type"] == type
      end
    )
  end

  def business_concept_version_upload(token, business_concepts) do
    headers = get_header(token)

    form =
      {:multipart,
       [
         {"file", business_concepts,
          {"form-data", [{"name", "business_concepts"}, {"filename", "business_concepts.csv"}]},
          [{"Content-Type", "text/csv"}]}
       ]}

    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.post!(Routes.business_concept_version_url(@endpoint, :upload), form, headers)

    {:ok, status_code}
  end

  def business_concept_alias_create(token, business_concept_id, attrs) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]
    body = %{"business_concept_alias" => attrs} |> JSON.encode!()

    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(
        Routes.business_concept_alias_url(@endpoint, :create, business_concept_id),
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
        Routes.business_concept_alias_url(@endpoint, :index, business_concept_id),
        headers,
        []
      )

    {:ok, status_code, resp |> JSON.decode!()}
  end

  def business_concept_alias_delete(token, id) do
    headers = [@headers, {"authorization", "Bearer #{token}"}]

    %HTTPoison.Response{status_code: status_code, body: _resp} =
      HTTPoison.delete!(Routes.business_concept_alias_url(@endpoint, :delete, id), headers, [])

    {:ok, status_code}
  end

  def business_concept_alias_by_name(token, business_concept_id, business_concept_alias) do
    {:ok, _status_code, json_resp} = business_concept_alias_list(token, business_concept_id)

    Enum.find(
      json_resp["data"],
      fn alias_item -> alias_item["name"] == business_concept_alias end
    )
  end

  def to_rich_text(nil), do: %{}
  def to_rich_text(""), do: %{}

  def to_rich_text(text) do
    %{
      document: %{
        nodes: [
          %{
            object: "block",
            type: "paragraph",
            nodes: [%{object: "text", leaves: [%{text: text}]}]
          }
        ]
      }
    }
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
