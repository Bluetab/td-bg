defmodule TdBgWeb.BusinessConceptFilterControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  alias TdBg.Permissions.MockPermissionResolver
  alias TdBg.Search.MockSearch
  alias TdBgWeb.ApiServices.MockTdAuditService
  alias TdBgWeb.ApiServices.MockTdAuthService

  @df_cache Application.get_env(:td_bg, :df_cache)

  setup_all do
    start_supervised MockTdAuthService
    start_supervised MockTdAuditService
    start_supervised MockPermissionResolver
    start_supervised(@df_cache)
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  @user_name "user"
  describe "index" do
    @tag :admin_authenticated
    test "lists all filters (admin user)", %{conn: conn} do
      conn = get conn, business_concept_filter_path(conn, :index)
      assert json_response(conn, 200)["data"] == MockSearch.get_filters(%{})
    end

    @tag authenticated_user: @user_name
    test "lists all filters (non-admin user)", %{conn: conn} do
      conn = get conn, business_concept_filter_path(conn, :index)
      assert json_response(conn, 200)["data"] == %{}
    end
  end

end
