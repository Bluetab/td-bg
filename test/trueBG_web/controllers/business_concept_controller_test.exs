defmodule TrueBGWeb.BusinessConceptControllerTest do
  use TrueBGWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"
  import TrueBGWeb.Authentication, only: :functions
  alias Poison, as: JSON

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  @admin_user_name "app-admin"

  describe "index" do
    @tag authenticated_user: @admin_user_name
    test "lists all business_concepts", %{conn: conn} do
      conn = get conn, business_concept_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create business_concept" do
    setup [:create_content_schema]

    @tag authenticated_user: @admin_user_name
    test "renders business_concept when data is valid", %{conn: conn, swagger_schema: schema} do
      data_domain = insert(:data_domain)

      creation_attrs = %{
        content: %{},
        type: "some type",
        name: "Some name",
        description: "Some description"
      }

      conn = post conn, data_domain_business_concept_path(conn, :create, data_domain.id), business_concept: creation_attrs
      validate_resp_schema(conn, schema, "BusinessConceptResponse")
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)

      conn = get conn, business_concept_path(conn, :show, id)
      validate_resp_schema(conn, schema, "BusinessConceptResponse")
      business_concept = json_response(conn, 200)["data"]

      %{id: id, last_change_by: Integer.mod(:binary.decode_unsigned(@admin_user_name), 100_000), version: 1}
        |> Enum.each(&(assert business_concept |> Map.get(Atom.to_string(elem(&1, 0))) == elem(&1, 1)))

      creation_attrs
        |> Enum.each(&(assert business_concept |> Map.get(Atom.to_string(elem(&1, 0))) == elem(&1, 1)))
    end

    @tag authenticated_user: @admin_user_name
    test "renders errors when data is invalid", %{conn: conn, swagger_schema: schema} do
      data_domain = insert(:data_domain)
      creation_attrs = %{
        content: %{},
        type: "some type",
        name: nil,
        description: "Some description",
      }
      conn = post conn, data_domain_business_concept_path(conn, :create, data_domain.id), business_concept: creation_attrs
      validate_resp_schema(conn, schema, "BusinessConceptResponse")
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update business_concept" do
    setup [:create_content_schema]

    @tag authenticated_user: @admin_user_name
    test "renders business_concept when data is valid", %{conn: conn, swagger_schema: schema} do
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by:  user.id)
      business_concept =  business_concept_version.business_concept
      business_concept_id = business_concept.id

      update_attrs = %{
        content: %{},
        name: "The new name",
        description: "The new description"
      }

      conn = put conn, business_concept_path(conn, :update, business_concept), business_concept: update_attrs
      validate_resp_schema(conn, schema, "BusinessConceptResponse")
      assert %{"id" => ^business_concept_id} = json_response(conn, 200)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get conn, business_concept_path(conn, :show, business_concept_id)
      validate_resp_schema(conn, schema, "BusinessConceptResponse")

      updated_businness_concept = json_response(conn, 200)["data"]

      update_attrs
        |> Enum.each(&(assert updated_businness_concept |> Map.get(Atom.to_string(elem(&1, 0))) == elem(&1, 1)))
    end

    @tag authenticated_user: @admin_user_name
    test "renders errors when data is invalid", %{conn: conn, swagger_schema: schema} do
      user = build(:user)
      business_concept_version = insert(:business_concept_version, last_change_by:  user.id)
      business_concept_id = business_concept_version.business_concept.id

      update_attrs = %{
        content: %{},
        name: nil,
        description: "The new description"
      }

      conn = put conn, business_concept_path(conn, :update, business_concept_id), business_concept: update_attrs
      validate_resp_schema(conn, schema, "BusinessConceptResponse")
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  # describe "delete business_concept" do
  #   @tag authenticated_user: @admin_user_name
  #   test "deletes chosen business_concept", %{conn: conn} do
  #     user = build(:user)
  #     business_concept_version = insert(:business_concept_version, last_change_by:  user.id)
  #     business_concept = business_concept_version.business_concept
  #
  #     conn = delete conn, business_concept_path(conn, :delete, business_concept)
  #     assert response(conn, 204)
  #
  #     conn = recycle_and_put_headers(conn)
  #
  #     assert_error_sent 404, fn ->
  #       get conn, business_concept_path(conn, :show, business_concept)
  #     end
  #   end
  # end

  def create_content_schema(_) do
    json_schema = %{"some type" => []} |> JSON.encode!
    path = Application.get_env(:trueBG, :bc_schema_location)
    File.write!(path, json_schema, [:write, :utf8])
  end
end
