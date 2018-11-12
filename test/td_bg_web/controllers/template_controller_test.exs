defmodule TdBgWeb.TemplateControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdBgWeb.Authentication, only: :functions

  alias TdBg.Accounts.User
  alias TdBg.Permissions.MockPermissionResolver
  alias TdBg.Taxonomies
  alias TdBgWeb.ApiServices.MockTdAuthService

  @df_cache Application.get_env(:td_bg, :df_cache)

  @create_attrs %{id: 0, content: [], label: "some name", name: "some_name", is_default: false}
  @domain_attrs %{name: "domain1", type: "type", description: "description"}

  setup_all do
    start_supervised(MockPermissionResolver)
    start_supervised(MockTdAuthService)
    start_supervised(@df_cache)
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "domain templates" do
    @tag :admin_authenticated
    test "relate domain and template", %{conn: conn, swagger_schema: schema} do
      conn = post(conn, domain_path(conn, :create), domain: @domain_attrs)
      validate_resp_schema(conn, schema, "DomainResponse")
      assert %{"id" => domain_id} = json_response(conn, 201)["data"]

      @df_cache.clean_cache()
      @df_cache.put_template(@create_attrs)

      conn = recycle_and_put_headers(conn)
      conn = get(conn, template_path(conn, :get_domain_templates, domain_id))
      validate_resp_schema(conn, schema, "TemplatesResponse")
      assert length(json_response(conn, 200)["data"]) == 1
    end
  end

  @tag authenticated_user: "user_name"
  test "get domain templates. Check role meta", %{conn: conn, swagger_schema: schema} do
    role_name = "role_name"

    @df_cache.clean_cache()
    @df_cache.put_template(%{
        id: 0,
        label: "some name",
        name: "some_name",
        is_default: false,
        content: [
          %{
            "name" => "dominio",
            "type" => "list",
            "label" => "label",
            "values" => [],
            "required" => false,
            "form_type" => "dropdown",
            "description" => "description",
            "meta" => %{"role" => role_name}
          }
        ]
    })

    role = MockTdAuthService.find_or_create_role(role_name)

    parent_domain = insert(:domain)
    {:ok, child_domain} = build(:child_domain, parent: parent_domain)
      |> Map.put(:parent_id, parent_domain.id)
      |> Map.take([:name, :description, :parent_id])
      |> Taxonomies.create_domain

    group_name = "group_name"
    group = MockTdAuthService.create_group(%{"group" => %{"name" => group_name}})
    group_user_name = "group_user_name"

    MockTdAuthService.create_user(%{
      "user" => %{
        "user_name" => group_user_name,
        "full_name" => "#{group_user_name}",
        "is_admin" => false,
        "password" => "password",
        "email" => "nobody@bluetab.net",
        "groups" => [%{"name" => group_name}]
      }
    })

    user_name = "user_name"

    MockPermissionResolver.create_acl_entry(%{
      principal_id: group.id,
      principal_type: "group",
      resource_id: parent_domain.id,
      resource_type: "domain",
      role_id: role.id
    })

    MockPermissionResolver.create_acl_entry(%{
      principal_id: User.gen_id_from_user_name(user_name),
      principal_type: "user",
      resource_id: child_domain.id,
      resource_type: "domain",
      role_id: role.id
    })

    conn =
      get(conn, template_path(conn, :get_domain_templates, child_domain.id, preprocess: true))

    validate_resp_schema(conn, schema, "TemplatesResponse")
    stored_templates = json_response(conn, 200)["data"]

    values =
      stored_templates
      |> Enum.at(0)
      |> Map.get("content")
      |> Enum.at(0)
      |> Map.get("values")

    default =
      stored_templates
      |> Enum.at(0)
      |> Map.get("content")
      |> Enum.at(0)
      |> Map.get("default")

    assert values |> Enum.sort == [group_user_name, user_name] |> Enum.sort
    assert default == user_name
  end
end
