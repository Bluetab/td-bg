defmodule TdBgWeb.SharedDomainControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import Assertions

  setup_all do
    start_supervised!(TdBg.Cache.ConceptLoader)
    start_supervised!(TdCore.Search.Cluster)
    start_supervised!(TdCore.Search.IndexWorker)
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
      claims: claims,
      swagger_schema: schema
    } do
      %{id: domain_id} = domain = insert(:domain)
      CacheHelpers.put_domain(domain)
      put_session_permissions(claims, domain_id, [:share_with_domain])

      %{id: concept_id} = insert(:business_concept, domain: domain)
      %{id: id1} = insert(:domain)
      %{id: id2} = insert(:domain)
      domain_ids = [id1, id2]

      assert %{"data" => data} =
               conn
               |> patch(
                 Routes.business_concept_shared_domain_path(conn, :update, concept_id),
                 %{"domain_ids" => domain_ids}
               )
               |> validate_resp_schema(schema, "BusinessConceptResponse")
               |> json_response(:ok)

      assert %{
               "id" => ^concept_id,
               "_embedded" => %{"shared_to" => [_ | _] = shared}
             } = data

      assert_lists_equal(shared, domain_ids, &(&1["id"] == &2))
    end

    @tag authentication: [user_name: "foo"]
    test "gets forbidden when user has no permissions", %{conn: conn, claims: %{jti: jti}} do
      %{id: domain_id} = domain = insert(:domain)
      CacheHelpers.put_domain(domain)

      TdCache.Permissions.cache_session_permissions!(jti, nil, %{
        "view_domain" => [domain_id]
      })

      %{id: concept_id} = insert(:business_concept, domain: domain)
      %{id: domain_id1} = insert(:domain)
      %{id: domain_id2} = insert(:domain)

      assert %{"errors" => errors} =
               conn
               |> patch(Routes.business_concept_shared_domain_path(conn, :update, concept_id), %{
                 "domain_ids" => [domain_id1, domain_id2]
               })
               |> json_response(:forbidden)

      assert %{"detail" => "Forbidden"} = errors
    end
  end
end
