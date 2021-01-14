defmodule TdBgWeb.DomainControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdBgWeb.Authentication, only: :functions
  import TdBgWeb.User, only: :functions
  import TdBg.TestOperators

  alias TdBg.Cache.ConceptLoader
  alias TdBg.Cache.DomainLoader
  alias TdBg.Permissions.MockPermissionResolver
  alias TdBg.Search.IndexWorker
  alias TdBg.Taxonomies
  alias TdBg.Taxonomies.Domain

  @create_attrs %{
    description: "some description",
    name: "some name",
    external_id: "domain external id"
  }
  @update_attrs %{
    description: "some updated description",
    name: "some updated name",
    external_id: "domain external id"
  }
  @invalid_attrs %{description: nil, name: nil}

  def fixture(:domain) do
    {:ok, domain} = Taxonomies.create_domain(@create_attrs)
    domain
  end

  setup_all do
    start_supervised(ConceptLoader)
    start_supervised(DomainLoader)
    start_supervised(IndexWorker)
    start_supervised(MockPermissionResolver)
    :ok
  end

  setup tags do
    tags
    |> Map.take([:authenticated_user, :conn])
    |> Map.new(fn
      {:authenticated_user, user_name} -> {:claims, create_claims(user_name)}
      {:conn, conn} -> {:conn, put_req_header(conn, "accept", "application/json")}
    end)
  end

  describe "index" do
    @tag :admin_authenticated
    test "lists all domains", %{conn: conn} do
      assert %{"data" => []} =
               conn
               |> get(Routes.domain_path(conn, :index))
               |> json_response(:ok)
    end
  end

  describe "index with actions" do
    @tag authenticated_user: "non_admin_user"
    test "list all domains user can view", %{
      conn: conn,
      swagger_schema: schema,
      claims: %{user_id: user_id}
    } do
      %{id: domain_id} = domain = insert(:domain)
      role = get_role_by_name("watch")

      MockPermissionResolver.create_acl_entry(%{
        principal_id: user_id,
        principal_type: "user",
        resource_id: domain.id,
        resource_type: "domain",
        role_id: role.id,
        role_name: role.name
      })

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

      role = get_role_by_name("publish")

      MockPermissionResolver.create_acl_entry(%{
        principal_id: user_id,
        principal_type: "user",
        resource_id: domain.id,
        resource_type: "domain",
        role_id: role.id,
        role_name: role.name
      })

      assert %{"data" => data} =
               conn
               |> get(Routes.domain_path(conn, :index, %{actions: "show, update"}))
               |> validate_resp_schema(schema, "DomainsResponse")
               |> json_response(:ok)

      assert [%{"id" => ^domain_id}] = data
    end

    @tag authenticated_user: "non_admin_user"
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
    @tag authenticated_user: "non_admin_user"
    test "includes parentable ids", %{
      conn: conn,
      swagger_schema: schema,
      claims: %{user_id: user_id}
    } do
      %{id: parent_id} = insert(:domain)
      %{id: sibling_id} = insert(:domain, parent_id: parent_id)
      %{id: domain_id} = domain = insert(:domain, parent_id: parent_id)
      %{id: role_id, name: role_name} = get_role_by_name("admin")

      [parent_id, domain_id, sibling_id]
      |> Enum.each(fn id ->
        MockPermissionResolver.create_acl_entry(%{
          principal_id: user_id,
          principal_type: "user",
          resource_id: id,
          resource_type: "domain",
          role_id: role_id,
          role_name: role_name
        })
      end)

      assert %{"data" => data} =
               conn
               |> get(Routes.domain_path(conn, :show, domain))
               |> validate_resp_schema(schema, "DomainResponse")
               |> json_response(:ok)

      assert %{"parentable_ids" => parentable_ids} = data
      assert parentable_ids <|> [parent_id, sibling_id]
    end
  end

  describe "create domain" do
    @tag :admin_authenticated
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
               "parent_id" => ^parent_id
             } = data
    end

    @tag :admin_authenticated
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

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn} do
      assert %{"errors" => errors} =
               conn
               |> post(Routes.domain_path(conn, :create), domain: @invalid_attrs)
               |> json_response(:unprocessable_entity)

      assert %{"name" => ["blank"]} = errors
    end
  end

  describe "update domain" do
    setup [:create_domain]

    @tag :admin_authenticated
    test "renders domain when data is valid", %{
      conn: conn,
      swagger_schema: schema,
      domain: %Domain{id: id} = domain
    } do
      assert %{"data" => data} =
               conn
               |> put(Routes.domain_path(conn, :update, domain), domain: @update_attrs)
               |> validate_resp_schema(schema, "DomainResponse")
               |> json_response(:ok)

      assert data["id"] == id
      assert data["description"] == "some updated description"
      assert data["name"] == "some updated name"
      assert data["parent_id"] == nil
      assert data["external_id"] == "domain external id"
    end

    @tag :admin_authenticated
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

    @tag authenticated_user: "non_admin_user"
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

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, domain: domain} do
      conn = put conn, Routes.domain_path(conn, :update, domain), domain: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete domain" do
    setup [:create_domain]

    @tag :admin_authenticated
    test "deletes chosen domain", %{conn: conn, domain: domain} do
      assert conn
             |> delete(Routes.domain_path(conn, :delete, domain))
             |> response(:no_content)

      assert_error_sent :not_found, fn ->
        get(conn, Routes.domain_path(conn, :show, domain))
      end
    end
  end

  describe "count business concept from domain given a user name" do
    setup [:create_domain]

    @tag :admin_authenticated
    test "fetch counter", %{conn: conn, swagger_schema: schema, domain: domain} do
      user_name = "My cool name"
      business_concept_1 = insert(:business_concept, domain: domain)
      business_concept_2 = insert(:business_concept, domain: domain)
      business_concept_3 = insert(:business_concept, domain: domain)

      insert(:business_concept_version,
        business_concept: business_concept_1,
        content: %{"data_owner" => user_name}
      )

      insert(:business_concept_version, business_concept: business_concept_2)

      insert(:business_concept_version,
        business_concept: business_concept_3,
        content: %{"data_owner" => user_name},
        status: "deprecated"
      )

      conn =
        get(
          conn,
          Routes.domain_domain_path(conn, :count_bc_in_domain_for_user, domain.id, user_name)
        )

      validate_resp_schema(conn, schema, "BCInDomainCountResponse")

      counter = json_response(conn, 200)["data"] |> Map.fetch!("counter")
      assert counter == 1
    end
  end

  defp create_domain(_) do
    domain = fixture(:domain)
    {:ok, domain: domain}
  end
end
