defmodule TdBgWeb.UserControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  import TdBgWeb.Authentication, only: :functions

  alias TdBg.Permissions.Role
  alias TdBgWeb.ApiServices.MockTdAuthService

  setup_all do
    start_supervised MockTdAuthService
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  @user_name "user"
  describe "query_user_data_domains" do
    @tag authenticated_user: @user_name
    test "list the data domains where the user has a permission create_business_concept",
      %{conn: conn, swagger_schema: schema} do
        user = create_user(@user_name)
        domain = insert(:domain)
        role = Role.get_role_by_name("create")
        insert(:acl_entry_domain_user, principal_id: user.id, resource_id: domain.id, role_id: role.id)
        conn = get conn, user_path(conn, :user_domains)
        validate_resp_schema(conn, schema, "UserDomainResponse")
    end
  end
end
