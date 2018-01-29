defmodule TrueBGWeb.BusinessConceptControllerTest do
  use TrueBGWeb.ConnCase
  # import TrueBGWeb.Authentication, only: :functions
  #
  # alias TrueBG.Taxonomies
  # alias TrueBG.Taxonomies.BusinessConcept

  # @create_attrs %{content: %{}, type: "some type"}
  # @update_attrs %{content: %{}, type: "some updated type"}
  # @invalid_attrs %{content: nil, type: nil}
  # @admin_user_name "app-admin"
  #
  # def fixture(:business_concept) do
  #   {:ok, business_concept} = Taxonomies.create_business_concept(@create_attrs)
  #   business_concept
  # end
  #
  # setup %{conn: conn} do
  #   {:ok, conn: put_req_header(conn, "accept", "application/json")}
  # end
  #
  # describe "index" do
  #   @tag authenticated_user: @admin_user_name
  #   test "lists all business_concepts", %{conn: conn} do
  #     conn = get conn, business_concept_path(conn, :index)
  #     assert json_response(conn, 200)["data"] == []
  #   end
  # end
  #
  # describe "create business_concept" do
  #   @tag authenticated_user: @admin_user_name
  #   test "renders business_concept when data is valid", %{conn: conn} do
  #     conn = post conn, business_concept_path(conn, :create), business_concept: @create_attrs
  #     assert %{"id" => id} = json_response(conn, 201)["data"]
  #
  #     conn = recycle_and_put_headers(conn)
  #
  #     conn = get conn, business_concept_path(conn, :show, id)
  #     assert json_response(conn, 200)["data"] == %{
  #       "id" => id,
  #       "content" => %{},
  #       "type" => "some type"}
  #   end
  #
  #   @tag authenticated_user: @admin_user_name
  #   test "renders errors when data is invalid", %{conn: conn} do
  #     conn = post conn, business_concept_path(conn, :create), business_concept: @invalid_attrs
  #     assert json_response(conn, 422)["errors"] != %{}
  #   end
  # end
  #
  # describe "update business_concept" do
  #   setup [:create_business_concept]
  #
  #   @tag authenticated_user: @admin_user_name
  #   test "renders business_concept when data is valid", %{conn: conn, business_concept: %BusinessConcept{id: id} = business_concept} do
  #     conn = put conn, business_concept_path(conn, :update, business_concept), business_concept: @update_attrs
  #     assert %{"id" => ^id} = json_response(conn, 200)["data"]
  #
  #     conn = recycle_and_put_headers(conn)
  #
  #     conn = get conn, business_concept_path(conn, :show, id)
  #     assert json_response(conn, 200)["data"] == %{
  #       "id" => id,
  #       "content" => %{},
  #       "type" => "some updated type"}
  #   end
  #
  #   @tag authenticated_user: @admin_user_name
  #   test "renders errors when data is invalid", %{conn: conn, business_concept: business_concept} do
  #     conn = put conn, business_concept_path(conn, :update, business_concept), business_concept: @invalid_attrs
  #     assert json_response(conn, 422)["errors"] != %{}
  #   end
  # end
  #
  # describe "delete business_concept" do
  #   setup [:create_business_concept]
  #
  #   @tag authenticated_user: @admin_user_name
  #   test "deletes chosen business_concept", %{conn: conn, business_concept: business_concept} do
  #     conn = delete conn, business_concept_path(conn, :delete, business_concept)
  #     assert response(conn, 204)
  #
  #     conn = recycle_and_put_headers(conn)
  #
  #     assert_error_sent 404, fn ->
  #       get conn, business_concept_path(conn, :show, business_concept)
  #     end
  #   end
  # end
  #
  # defp create_business_concept(_) do
  #   business_concept = fixture(:business_concept)
  #   {:ok, business_concept: business_concept}
  # end
end
