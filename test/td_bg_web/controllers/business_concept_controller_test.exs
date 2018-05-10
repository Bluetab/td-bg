defmodule TdBgWeb.BusinessConceptControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdBgWeb.Authentication, only: :functions

  alias TdBgWeb.ApiServices.MockTdAuthService
  alias Poison, as: JSON
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.Permissions

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  @admin_user_name "app-admin"

  describe "index" do
    @tag authenticated_user: @admin_user_name
    test "lists all business_concepts", %{conn: conn} do
      conn = get conn, business_concept_path(conn, :index)
      assert json_response(conn, 200)["data"]["collection"] == []
    end
  end

  describe "search" do
    @tag authenticated_user: @admin_user_name
    test "find business_concepts by id and status", %{conn: conn} do
      published = BusinessConcept.status.published
      draft = BusinessConcept.status.draft
      domain = insert(:domain)
      id = [create_version(domain, "one", draft).business_concept.id]
      id = [create_version(domain, "two", published).business_concept.id | id]
      id = [create_version(domain, "three", published).business_concept.id | id]

      conn = get conn, business_concept_path(conn, :search), %{id: Enum.join(id, ","), status: published}
      assert 2 == length(json_response(conn, 200)["data"])
    end

    defp create_version(domain, name, status) do
      business_concept = insert(:business_concept, domain: domain)
      insert(:business_concept_version, business_concept: business_concept, name: name, status: status)
    end

  end

  describe "query_business_concept_taxonomy" do
    @tag authenticated_user: @admin_user_name
    test "list the taxonomies of a business concept", %{conn: conn} do
      published = BusinessConcept.status.published
      user = build(:user)
      user = create_user(user.user_name, is_admin: true)
      domain = insert(:domain)
      role = Permissions.get_role_by_name("watch")
      insert(:acl_entry_domain_user, principal_id: user.id, resource_id: domain.id, role: role)
      business_concept_version = create_version(domain, "one", published)
      id = business_concept_version.business_concept.id
      conn = recycle_and_put_headers(conn)
      conn = get conn, business_concept_business_concept_path(conn, :taxonomy_roles, id)
      collection = json_response(conn, 200)["data"]["collection"]
      assert Enum.member?(Enum.map(collection, &(&1["domain_name"])), domain.name)
      assert Enum.member?(Enum.map(collection, &(&1["domain_id"])), domain.id)
      roles = Enum.find(collection, &(&1["domain_name"] == domain.name))["roles"]
      assert Enum.member?(Enum.map(roles, &(&1["principal"]["id"])), user.id)
    end
  end

  describe "search_by_name" do
    @tag authenticated_user: @admin_user_name
    test "find business concept by name", %{conn: conn} do
      published = BusinessConcept.status.published
      draft = BusinessConcept.status.draft
      domain = insert(:domain)
      id = [create_version(domain, "one", draft).business_concept.id]
      id = [create_version(domain, "two", published).business_concept.id | id]
      [create_version(domain, "two", published).business_concept.id | id]

      conn = get conn, business_concept_path(conn, :search_by_name, "two")
      assert 2 == length(json_response(conn, 200)["data"])

      conn = recycle_and_put_headers(conn)
      conn = get conn, business_concept_path(conn, :search_by_name, "one")
      assert 1 == length(json_response(conn, 200)["data"])
    end
  end

  describe "create business_concept" do
    setup [:create_template]

    @tag authenticated_user: @admin_user_name
    test "renders business_concept when data is valid", %{conn: conn, swagger_schema: schema} do
      domain = insert(:domain)

      creation_attrs = %{
        content: %{},
        type: "some type",
        name: "Some name",
        description: "Some description",
        domain_id: domain.id
      }

      conn = post conn, business_concept_path(conn, :create), business_concept: creation_attrs
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
      domain = insert(:domain)
      creation_attrs = %{
        content: %{},
        type: "some type",
        name: nil,
        description: "Some description",
        domain_id: domain.id
      }
      conn = post conn, business_concept_path(conn, :create), business_concept: creation_attrs
      validate_resp_schema(conn, schema, "BusinessConceptResponse")
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update business_concept" do
    setup [:create_template]

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

  describe "update business_concept status" do
    setup [:create_template]

    @transitions  [{BusinessConcept.status.draft, BusinessConcept.status.pending_approval},
                   {BusinessConcept.status.pending_approval, BusinessConcept.status.published},
                   {BusinessConcept.status.pending_approval, BusinessConcept.status.rejected},
                   {BusinessConcept.status.rejected, BusinessConcept.status.pending_approval},
                   {BusinessConcept.status.published, BusinessConcept.status.deprecated},
                  ]

    Enum.each(@transitions, fn(transition) ->
      status_from = elem(transition, 0)
      status_to = elem(transition, 1)

      @tag authenticated_user: @admin_user_name, status_from: status_from, status_to: status_to
      test "update business_concept status change from #{status_from} to #{status_to}", %{conn: conn, swagger_schema: schema, status_from: status_from, status_to: status_to} do
          user = build(:user)
          business_concept_version = insert(:business_concept_version, status: status_from, last_change_by:  user.id)
          business_concept =  business_concept_version.business_concept
          business_concept_id = business_concept.id

          update_attrs = %{
            status: status_to,
          }

          conn = patch conn, business_concept_business_concept_path(conn, :update_status, business_concept), business_concept: update_attrs
          validate_resp_schema(conn, schema, "BusinessConceptResponse")
          assert %{"id" => ^business_concept_id} = json_response(conn, 200)["data"]

          conn = recycle_and_put_headers(conn)
          conn = get conn, business_concept_path(conn, :show, business_concept_id)
          validate_resp_schema(conn, schema, "BusinessConceptResponse")

          assert json_response(conn, 200)["data"]["status"] == status_to
      end
    end)
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

  def create_template(_) do
    headers = get_header(get_user_token("app-admin"))
    attrs = %{}
      |> Map.put("name", "some type")
      |> Map.put("content", [])
    body = %{template: attrs} |> JSON.encode!
    HTTPoison.post!(template_url(@endpoint, :create), body, headers, [])
    :ok
  end
end
