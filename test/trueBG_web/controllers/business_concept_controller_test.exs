defmodule TrueBGWeb.BusinessConceptControllerTest do
  use TrueBGWeb.ConnCase
  import TrueBGWeb.Authentication, only: :functions

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  @admin_user_name "app-admin"

  describe "index" do
    @tag authenticated_user: @admin_user_name
    test "lists all business_concepts", %{conn: conn} do
      conn = get conn, business_concept_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create business_concept" do
    @tag authenticated_user: @admin_user_name
    test "renders business_concept when data is valid", %{conn: conn} do
      data_domain = insert(:data_domain)

      creation_attrs = %{
        content: %{},
        type: "Some type",
        name: "Some name",
        description: "Some description",
        data_domain_id: data_domain.id
      }

      conn = post conn, business_concept_path(conn, :create), business_concept: creation_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = recycle_and_put_headers(conn)

      conn = get conn, business_concept_path(conn, :show, id)
      business_concept = json_response(conn, 200)["data"]

      %{id: id, modifier: 1, version: 1}
        |> Enum.each(&(assert business_concept |> Map.get(Atom.to_string(elem(&1, 0))) == elem(&1, 1)))

      creation_attrs
        |> Enum.each(&(assert business_concept |> Map.get(Atom.to_string(elem(&1, 0))) == elem(&1, 1)))
    end

    @tag authenticated_user: @admin_user_name
    test "renders errors when data is invalid", %{conn: conn} do
      creation_attrs = %{
        content: nil,
        type: nil,
        name: nil,
        description: "Some description",
        data_domain_id: nil
      }
      conn = post conn, business_concept_path(conn, :create), business_concept: creation_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update business_concept" do
    @tag authenticated_user: @admin_user_name
    test "renders business_concept when data is valid", %{conn: conn} do
      user = insert(:user)
      business_concept = insert(:business_concept, modifier:  user.id)
      id =  business_concept |> Map.get(:id)

      update_attrs = %{
        content: %{"Hola" => "Mundo"},
        name: "The new name",
        description: "The new description"
      }

      conn = put conn, business_concept_path(conn, :update, business_concept), business_concept: update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = recycle_and_put_headers(conn)
      conn = get conn, business_concept_path(conn, :show, id)

      updated_businness_concept = json_response(conn, 200)["data"]

      update_attrs
        |> Enum.each(&(assert updated_businness_concept |> Map.get(Atom.to_string(elem(&1, 0))) == elem(&1, 1)))
    end

    @tag authenticated_user: @admin_user_name
    test "renders errors when data is invalid", %{conn: conn} do
      user = insert(:user)
      business_concept = insert(:business_concept, modifier:  user.id)

      update_attrs = %{
        content: nil,
        name: nil,
        description: "The new description"
      }

      conn = put conn, business_concept_path(conn, :update, business_concept), business_concept: update_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete business_concept" do
    @tag authenticated_user: @admin_user_name
    test "deletes chosen business_concept", %{conn: conn} do
      user = insert(:user)
      business_concept = insert(:business_concept, modifier:  user.id)

      conn = delete conn, business_concept_path(conn, :delete, business_concept)
      assert response(conn, 204)

      conn = recycle_and_put_headers(conn)

      assert_error_sent 404, fn ->
        get conn, business_concept_path(conn, :show, business_concept)
      end
    end
  end

end
