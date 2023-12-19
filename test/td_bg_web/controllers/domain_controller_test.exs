defmodule TdBgWeb.DomainControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import Assertions
  import Mox

  setup_all do
    start_supervised!(TdBg.Cache.ConceptLoader)
    start_supervised!(TdBg.Cache.DomainLoader)
    start_supervised!(TdCore.Search.Cluster)
    :ok
  end

  describe "index" do
    setup do
      [domain: insert(:domain)]
    end

    @tag authentication: [role: "admin"]
    test "lists all domains", %{conn: conn} do
      assert %{"data" => [_]} =
               conn
               |> get(Routes.domain_path(conn, :index))
               |> json_response(:ok)
    end

    @tag authentication: [role: "service"]
    test "service account can list domains", %{conn: conn} do
      assert %{"data" => [_]} =
               conn
               |> get(Routes.domain_path(conn, :index))
               |> json_response(:ok)
    end

    @tag authentication: [role: "user"]
    test "user account cannot list domains", %{conn: conn} do
      assert %{"data" => []} =
               conn
               |> get(Routes.domain_path(conn, :index))
               |> json_response(:ok)
    end
  end

  describe "index with actions" do
    setup :verify_on_exit!

    @tag authentication: [user_name: "non_admin_user"]
    test "list all domains user can view", %{conn: conn, swagger_schema: schema, claims: claims} do
      %{id: domain_id} = domain = insert(:domain)
      CacheHelpers.put_domain(domain)

      put_session_permissions(claims, %{"view_domain" => [domain_id]})

      assert %{"data" => data} =
               conn
               |> get(Routes.domain_path(conn, :index, %{actions: "show, update"}))
               |> validate_resp_schema(schema, "DomainsResponse")
               |> json_response(:ok)

      assert [%{"id" => ^domain_id}] = data

      assert %{"data" => data} =
               conn
               |> get(Routes.domain_path(conn, :index, %{actions: "show, update", filter: "all"}))
               |> validate_resp_schema(schema, "DomainsResponse")
               |> json_response(:ok)

      assert [] = data

      put_session_permissions(claims, domain_id, ["view_domain", "publish_business_concept"])

      assert %{"data" => data} =
               conn
               |> get(Routes.domain_path(conn, :index, %{actions: "show, update"}))
               |> validate_resp_schema(schema, "DomainsResponse")
               |> json_response(:ok)

      assert [%{"id" => ^domain_id}] = data
    end

    @tag authentication: [user_name: "non_admin_user"]
    test "list all domains user has permission over specified actions", %{
      conn: conn,
      swagger_schema: schema,
      claims: claims
    } do
      %{id: domain_id} = domain = insert(:domain)
      CacheHelpers.put_domain(domain)

      actions = "view_dashboard, view_quality_rule"

      assert %{"data" => data} =
               conn
               |> get(Routes.domain_path(conn, :index, %{actions: actions}))
               |> validate_resp_schema(schema, "DomainsResponse")
               |> json_response(:ok)

      assert [] = data

      put_session_permissions(claims, %{
        "view_dashboard" => [domain_id],
        "view_quality_rule" => [domain_id]
      })

      assert %{"data" => data} =
               conn
               |> get(Routes.domain_path(conn, :index, %{actions: actions, filter: "all"}))
               |> validate_resp_schema(schema, "DomainsResponse")
               |> json_response(:ok)

      assert [%{"id" => ^domain_id}] = data
    end

    @tag authentication: [user_name: "non_admin_user"]
    test "user cant view any domain", %{conn: conn, swagger_schema: schema} do
      insert(:domain)

      assert %{"data" => []} =
               conn
               |> get(Routes.domain_path(conn, :index, %{actions: "show"}))
               |> validate_resp_schema(schema, "DomainsResponse")
               |> json_response(:ok)
    end
  end

  describe "GET /api/domains/:id" do
    @tag authentication: [user_name: "non_admin_user"]
    test "includes parentable ids", %{
      conn: conn,
      swagger_schema: schema,
      claims: claims
    } do
      %{id: parent_id} = parent = insert(:domain)
      %{id: sibling_id} = sibling = insert(:domain, parent_id: parent_id)
      domain = insert(:domain, parent_id: parent_id)

      for d <- [parent, sibling, domain], do: CacheHelpers.put_domain(d)

      put_session_permissions(claims, %{
        "view_domain" => [parent_id],
        "create_domain" => [parent_id],
        "delete_domain" => [parent_id],
        "update_domain" => [parent_id]
      })

      assert %{"data" => data} =
               conn
               |> get(Routes.domain_path(conn, :show, domain))
               |> validate_resp_schema(schema, "DomainResponse")
               |> json_response(:ok)

      assert %{"parentable_ids" => parentable_ids} = data
      assert_lists_equal(parentable_ids, [parent_id, sibling_id])
    end
  end

  describe "create domain" do
    @tag authentication: [role: "admin"]
    test "renders domain when data is valid", %{conn: conn, swagger_schema: schema} do
      %{id: parent_id} = insert(:domain)

      %{description: description, name: name, external_id: external_id, parent_id: ^parent_id} =
        params =
        build(:domain, parent_id: parent_id)
        |> Map.take([:description, :name, :external_id, :parent_id])

      assert %{"data" => data} =
               conn
               |> post(Routes.domain_path(conn, :create), domain: params)
               |> validate_resp_schema(schema, "DomainResponse")
               |> json_response(:created)

      assert %{
               "description" => ^description,
               "external_id" => ^external_id,
               "name" => ^name,
               "parent_id" => ^parent_id,
               "id" => domain_id
             } = data

      on_exit(fn -> TdCache.TaxonomyCache.delete_domain(domain_id, clean: true) end)
    end

    @tag authentication: [role: "admin"]
    test "returns unprocessable_entity and errors when parent is missing", %{conn: conn} do
      params =
        build(:domain, parent_id: 1_234_567)
        |> Map.take([:description, :name, :external_id, :parent_id])

      assert %{"errors" => errors} =
               conn
               |> post(Routes.domain_path(conn, :create), domain: params)
               |> json_response(:unprocessable_entity)

      assert %{"parent_id" => ["does not exist"]} = errors
    end

    @tag authentication: [role: "admin"]
    test "renders errors when data is invalid", %{conn: conn} do
      params = %{"name" => nil}

      assert %{"errors" => errors} =
               conn
               |> post(Routes.domain_path(conn, :create), domain: params)
               |> json_response(:unprocessable_entity)

      assert %{"name" => ["blank"]} = errors
    end
  end

  describe "update domain" do
    setup :create_domain

    @tag authentication: [role: "admin"]
    test "renders domain when data is valid", %{
      conn: conn,
      swagger_schema: schema,
      domain: %{id: id} = domain
    } do
      params = %{
        description: "some updated description",
        name: "some updated name",
        external_id: "domain external id"
      }

      assert %{"data" => data} =
               conn
               |> put(Routes.domain_path(conn, :update, domain), domain: params)
               |> validate_resp_schema(schema, "DomainResponse")
               |> json_response(:ok)

      assert data["id"] == id
      assert data["description"] == "some updated description"
      assert data["name"] == "some updated name"
      assert data["parent_id"] == nil
      assert data["external_id"] == "domain external id"
    end

    @tag authentication: [role: "admin"]
    test "updates parent_id if user has permission to update domain parent", %{
      conn: conn,
      swagger_schema: schema,
      domain: domain
    } do
      %{id: parent_id} = insert(:domain)

      assert %{"data" => data} =
               conn
               |> patch(Routes.domain_path(conn, :update, domain),
                 domain: %{"parent_id" => parent_id}
               )
               |> validate_resp_schema(schema, "DomainResponse")
               |> json_response(:ok)

      assert %{"parent_id" => ^parent_id} = data
    end

    @tag authentication: [user_name: "non_admin_user"]
    test "returns forbidden if user doesn't have permission to update domain parent", %{
      conn: conn,
      domain: domain
    } do
      %{id: parent_id} = insert(:domain)

      assert %{"errors" => _errors} =
               conn
               |> patch(Routes.domain_path(conn, :update, domain),
                 domain: %{"parent_id" => parent_id}
               )
               |> json_response(:forbidden)
    end

    @tag authentication: [role: "admin"]
    test "renders errors when data is invalid", %{conn: conn, domain: domain} do
      params = %{"name" => nil}

      assert %{"errors" => errors} =
               conn
               |> put(Routes.domain_path(conn, :update, domain), domain: params)
               |> json_response(:unprocessable_entity)

      assert %{"name" => ["blank"]} = errors
    end
  end

  describe "delete domain" do
    setup :create_domain

    @tag authentication: [role: "admin"]
    test "deletes chosen domain", %{conn: conn, domain: domain} do
      assert conn
             |> delete(Routes.domain_path(conn, :delete, domain))
             |> response(:no_content)

      assert_error_sent(:not_found, fn ->
        get(conn, Routes.domain_path(conn, :show, domain))
      end)
    end
  end

  describe "count business concept from domain given a user name" do
    setup :create_domain

    @tag authentication: [role: "admin"]
    test "fetch counter", %{conn: conn, swagger_schema: schema, domain: domain} do
      bcv = insert(:business_concept_version)
      %{id: child_id} = CacheHelpers.insert_domain(parent_id: domain.id)

      ElasticsearchMock
      |> expect(:request, fn _, :post, "/concepts/_search", %{query: query, size: 0}, _ ->
        assert %{
                 bool: %{
                   filter: [
                     %{term: %{current: true}},
                     %{terms: %{domain_id: domain_ids}},
                     %{query_string: %{query: "content.\\*:(\"user name\")"}}
                   ],
                   must_not: %{term: %{status: "deprecated"}}
                 }
               } = query

        assert_lists_equal(domain_ids, [domain.id, child_id])
        SearchHelpers.hits_response([bcv])
      end)

      user_name = "User Name"

      assert %{"data" => data} =
               conn
               |> get(
                 Routes.domain_domain_path(
                   conn,
                   :count_bc_in_domain_for_user,
                   domain.id,
                   user_name
                 )
               )
               |> validate_resp_schema(schema, "BCInDomainCountResponse")
               |> json_response(:ok)

      assert %{"counter" => 1} = data
    end
  end

  defp create_domain(_) do
    [domain: CacheHelpers.insert_domain()]
  end
end
