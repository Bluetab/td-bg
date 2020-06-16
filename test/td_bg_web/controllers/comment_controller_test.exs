defmodule TdBgWeb.CommentControllerTest do
  use TdBgWeb.ConnCase
  use PhoenixSwagger.SchemaTest, "priv/static/swagger.json"

  setup_all do
    start_supervised(TdBg.Permissions.MockPermissionResolver)
    start_supervised(TdBgWeb.ApiServices.MockTdAuthService)
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "GET /api/business_concepts/comments" do
    @tag :admin_authenticated
    test "returns ok and json if comment exists", %{conn: conn, swagger_schema: schema} do
      %{id: id, content: content, resource_id: resource_id} = insert(:comment)

      assert %{"data" => data} =
               conn
               |> get(Routes.comment_path(conn, :show, id))
               |> validate_resp_schema(schema, "CommentResponse")
               |> json_response(:ok)

      assert %{"content" => ^content, "resource_id" => ^resource_id} = data
    end
  end

  describe "POST /api/business_concepts/comments" do
    @tag :admin_authenticated
    test "returns created and json if comment was created", %{conn: conn, swagger_schema: schema} do
      %{"content" => content, "resource_id" => resource_id} = params = string_params_for(:comment)

      assert %{"data" => data} =
               conn
               |> post(Routes.comment_path(conn, :create, %{"comment" => params}))
               |> validate_resp_schema(schema, "CommentResponse")
               |> json_response(:created)

      assert %{"content" => ^content, "resource_id" => ^resource_id} = data
    end
  end

  describe "DELETE /api/business_concepts/comments/:id" do
    @tag :admin_authenticated
    test "returns not found if comment does not exist", %{conn: conn} do
      assert conn
             |> delete(Routes.comment_path(conn, :delete, 123))
             |> response(:not_found)
    end

    @tag :admin_authenticated
    test "returns no content if comment is deleted", %{conn: conn} do
      %{id: id} = insert(:comment)

      assert conn
             |> delete(Routes.comment_path(conn, :delete, id))
             |> response(:no_content)
    end
  end
end
