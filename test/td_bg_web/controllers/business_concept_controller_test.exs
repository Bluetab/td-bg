defmodule TdBgWeb.BusinessConceptControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdBgWeb.Authentication, only: :functions

  alias TdBgWeb.ApiServices.MockTdAuthService
  alias Poison, as: JSON
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.Permissions.MockPermissionResolver

  setup_all do
    start_supervised(MockTdAuthService)
    start_supervised(MockPermissionResolver)
    :ok
  end

  defp to_rich_text(plain) do
    %{"document" => plain}
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "update business_concept" do
    setup [:create_template]

    @tag :admin_authenticated
    test "renders business_concept when data is valid", %{conn: conn, swagger_schema: schema} do
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by: user.id)
      business_concept = business_concept_version.business_concept
      business_concept_id = business_concept.id

      update_attrs = %{
        content: %{},
        name: "The new name",
        description: to_rich_text("The new description")
      }

      conn =
        put(
          conn,
          business_concept_path(conn, :update, business_concept),
          business_concept: update_attrs
        )

      validate_resp_schema(conn, schema, "BusinessConceptResponse")
      assert %{"id" => ^business_concept_id} = json_response(conn, 200)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get(conn, business_concept_path(conn, :show, business_concept_id))
      validate_resp_schema(conn, schema, "BusinessConceptResponse")

      updated_business_concept = json_response(conn, 200)["data"]

      update_attrs
      |> Enum.each(
        &assert updated_business_concept |> Map.get(Atom.to_string(elem(&1, 0))) == elem(&1, 1)
      )
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, swagger_schema: schema} do
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by: user.id)
      business_concept_id = business_concept_version.business_concept.id

      update_attrs = %{
        content: %{},
        name: nil,
        description: to_rich_text("The new description")
      }

      conn =
        put(
          conn,
          business_concept_path(conn, :update, business_concept_id),
          business_concept: update_attrs
        )

      validate_resp_schema(conn, schema, "BusinessConceptResponse")
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update business_concept status" do
    setup [:create_template]

    @transitions [
      {BusinessConcept.status().draft, BusinessConcept.status().pending_approval},
      {BusinessConcept.status().pending_approval, BusinessConcept.status().published},
      {BusinessConcept.status().pending_approval, BusinessConcept.status().rejected},
      {BusinessConcept.status().rejected, BusinessConcept.status().draft},
      {BusinessConcept.status().published, BusinessConcept.status().deprecated}
    ]

    Enum.each(@transitions, fn transition ->
      status_from = elem(transition, 0)
      status_to = elem(transition, 1)

      # Why do I need to pass a value ???
      @tag admin_authenticated: "xyz", status_from: status_from, status_to: status_to
      test "update business_concept status change from #{status_from} to #{status_to}", %{
        conn: conn,
        swagger_schema: schema,
        status_from: status_from,
        status_to: status_to
      } do
        user = build(:user)

        business_concept_version =
          insert(:business_concept_version, status: status_from, last_change_by: user.id)

        business_concept = business_concept_version.business_concept
        business_concept_id = business_concept.id

        update_attrs = %{
          status: status_to
        }

        conn =
          patch(
            conn,
            business_concept_business_concept_path(conn, :update_status, business_concept),
            business_concept: update_attrs
          )

        validate_resp_schema(conn, schema, "BusinessConceptResponse")
        assert %{"id" => ^business_concept_id} = json_response(conn, 200)["data"]

        conn = recycle_and_put_headers(conn)
        conn = get(conn, business_concept_path(conn, :show, business_concept_id))
        validate_resp_schema(conn, schema, "BusinessConceptResponse")

        assert json_response(conn, 200)["data"]["status"] == status_to
      end
    end)
  end

  defp create_template(_) do
    headers = get_header(get_user_token("app-admin"))

    attrs =
      %{}
      |> Map.put("name", "some type")
      |> Map.put("content", [])
      |> Map.put("is_default", false)

    body = %{template: attrs} |> JSON.encode!()
    HTTPoison.post!(template_url(@endpoint, :create), body, headers, [])
    :ok
  end
end
