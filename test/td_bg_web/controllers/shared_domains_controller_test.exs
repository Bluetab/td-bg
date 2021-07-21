defmodule TdBgWeb.SharedDomainControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  alias TdBg.Cache.ConceptLoader
  alias TdBg.Search.IndexWorker

  setup_all do
    start_supervised(ConceptLoader)
    start_supervised(IndexWorker)
    :ok
  end

  describe "patch" do
    @tag authentication: [role: "admin"]
    test "shares a business concept with domains", %{conn: conn, swagger_schema: schema} do
      %{id: concept_id} = insert(:business_concept)
      %{id: domain_id1} = insert(:domain)
      %{id: domain_id2} = insert(:domain)
      body = %{domain_ids: [domain_id1, domain_id2]}

      conn =
        patch(conn, Routes.business_concept_shared_domain_path(conn, :update, concept_id), body)

      assert %{
               "data" => %{
                 "id" => ^concept_id,
                 "_embedded" => %{"shared_to" => shared_domains}
               }
             } =
               conn
               |> validate_resp_schema(schema, "BusinessConceptResponse")
               |> json_response(:ok)

      assert Enum.find(shared_domains, fn domain -> domain["id"] == domain_id1 end)
      assert Enum.find(shared_domains, fn domain -> domain["id"] == domain_id2 end)
    end

    @tag authentication: [role: "admin"]
    test "gets not found when concept does not exist", %{conn: conn} do
      concept_id = System.unique_integer([:positive])
      %{id: domain_id1} = insert(:domain)
      %{id: domain_id2} = insert(:domain)
      body = %{domain_ids: [domain_id1, domain_id2]}

      conn =
        patch(conn, Routes.business_concept_shared_domain_path(conn, :update, concept_id), body)

      assert %{"errors" => %{"detail" => "Not found"}} = json_response(conn, :not_found)
    end

    @tag authentication: [user_name: "foo"]
    test "shares a business concept with domains when user has permissions", %{
      conn: conn,
      claims: %{user_id: user_id},
      swagger_schema: schema
    } do
      %{id: domain_id} = domain = insert(:domain)
      create_acl_entry(user_id, "domain", domain_id, "create")
      create_acl_entry(user_id, "domain", domain_id, [:share_with_domain])
      %{id: concept_id} = insert(:business_concept, domain: domain)
      %{id: domain_id1} = insert(:domain)
      %{id: domain_id2} = insert(:domain)
      domain_ids = [domain_id1, domain_id2]
      body = %{domain_ids: domain_ids}

      conn =
        patch(conn, Routes.business_concept_shared_domain_path(conn, :update, concept_id), body)

      assert %{
               "data" => %{
                 "id" => ^concept_id,
                 "_embedded" => %{"shared_to" => [_ | _] = shared}
               }
             } =
               conn
               |> validate_resp_schema(schema, "BusinessConceptResponse")
               |> json_response(:ok)

      assert Enum.all?(shared, &(Map.get(&1, "id") in domain_ids))
    end

    @tag authentication: [user_name: "foo"]
    test "gets forbidden when user has no permissions", %{
      conn: conn,
      claims: %{user_id: user_id}
    } do
      %{id: domain_id} = domain = insert(:domain)
      create_acl_entry(user_id, "domain", domain_id, "watch")
      %{id: concept_id} = insert(:business_concept, domain: domain)
      %{id: domain_id1} = insert(:domain)
      %{id: domain_id2} = insert(:domain)
      body = %{domain_ids: [domain_id1, domain_id2]}

      conn =
        patch(conn, Routes.business_concept_shared_domain_path(conn, :update, concept_id), body)

      assert %{"errors" => %{"detail" => "Forbidden"}} = json_response(conn, :forbidden)
    end
  end
end
