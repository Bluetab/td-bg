defmodule TrueBGWeb.DomainGroupControllerTest do
  use TrueBGWeb.ConnCase

  alias TrueBG.Taxonomies
  alias TrueBG.Taxonomies.DomainGroup

  @create_attrs %{description: "some description", name: "some name"}
  @update_attrs %{description: "some updated description", name: "some updated name"}
  @invalid_attrs %{description: nil, name: nil}

  def fixture(:domain_group) do
    {:ok, domain_group} = Taxonomies.create_domain_group(@create_attrs)
    domain_group
  end

  def put_auth_headers(conn, jwt) do
    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("authorization", "Bearer #{jwt}")
  end

  setup %{conn: conn, jwt: _jwt} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag :admin_authenticated
    test "lists all domain_groups", %{conn: conn, jwt: jwt} do
      conn = conn
             |> put_auth_headers(jwt)
      conn = get conn, domain_group_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create domain_group" do
    @tag :admin_authenticated
    test "renders domain_group when data is valid", %{conn: conn, jwt: jwt} do
      conn = conn
             |> put_auth_headers(jwt)
      conn = post conn, domain_group_path(conn, :create), domain_group: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = conn
             |> recycle()
             |> put_auth_headers(jwt)

      conn = get conn, domain_group_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "description" => "some description",
        "name" => "some name",
        "parent_id" => nil}
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, jwt: jwt} do
      conn = conn
             |> put_auth_headers(jwt)
      conn = post conn, domain_group_path(conn, :create), domain_group: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update domain_group" do
    setup [:create_domain_group]

    @tag :admin_authenticated
    test "renders domain_group when data is valid", %{conn: conn, jwt: jwt, domain_group: %DomainGroup{id: id} = domain_group} do
      conn = conn
             |> put_auth_headers(jwt)
      conn = put conn, domain_group_path(conn, :update, domain_group), domain_group: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = conn
             |> recycle()
             |> put_auth_headers(jwt)

      conn = get conn, domain_group_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "description" => "some updated description",
        "name" => "some updated name",
        "parent_id" => nil}
    end

    @tag :admin_authenticated
    test "renders errors when data is invalid", %{conn: conn, jwt: jwt,  domain_group: domain_group} do
      conn = conn
             |> put_auth_headers(jwt)
      conn = put conn, domain_group_path(conn, :update, domain_group), domain_group: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete domain_group" do
    setup [:create_domain_group]

    @tag :admin_authenticated
    test "deletes chosen domain_group", %{conn: conn, jwt: jwt,  domain_group: domain_group} do
      conn = conn
             |> put_auth_headers(jwt)
      conn = delete conn, domain_group_path(conn, :delete, domain_group)
      assert response(conn, 204)

      conn = conn
             |> recycle()
             |> put_auth_headers(jwt)

      assert_error_sent 404, fn ->
        get conn, domain_group_path(conn, :show, domain_group)
      end
    end
  end

  defp create_domain_group(_) do
    domain_group = fixture(:domain_group)
    {:ok, domain_group: domain_group}
  end
end
