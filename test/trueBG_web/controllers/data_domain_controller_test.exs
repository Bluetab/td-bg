defmodule TrueBGWeb.DataDomainControllerTest do
  use TrueBGWeb.ConnCase

  alias TrueBG.Taxonomies
  alias TrueBG.Taxonomies.DataDomain

  @create_attrs %{description: "some description", name: "some name"}
  @update_attrs %{description: "some updated description", name: "some updated name"}
  @invalid_attrs %{description: nil, name: nil}

  def fixture(:data_domain) do
    {:ok, data_domain} = Taxonomies.create_data_domain(@create_attrs)
    data_domain
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all data_domains", %{conn: conn} do
      conn = get conn, data_domain_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create data_domain" do
    test "renders data_domain when data is valid", %{conn: conn} do
      conn = post conn, data_domain_path(conn, :create), data_domain: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, data_domain_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "description" => "some description",
        "name" => "some name"}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, data_domain_path(conn, :create), data_domain: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update data_domain" do
    setup [:create_data_domain]

    test "renders data_domain when data is valid", %{conn: conn, data_domain: %DataDomain{id: id} = data_domain} do
      conn = put conn, data_domain_path(conn, :update, data_domain), data_domain: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, data_domain_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "description" => "some updated description",
        "name" => "some updated name"}
    end

    test "renders errors when data is invalid", %{conn: conn, data_domain: data_domain} do
      conn = put conn, data_domain_path(conn, :update, data_domain), data_domain: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete data_domain" do
    setup [:create_data_domain]

    test "deletes chosen data_domain", %{conn: conn, data_domain: data_domain} do
      conn = delete conn, data_domain_path(conn, :delete, data_domain)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, data_domain_path(conn, :show, data_domain)
      end
    end
  end

  defp create_data_domain(_) do
    data_domain = fixture(:data_domain)
    {:ok, data_domain: data_domain}
  end
end
