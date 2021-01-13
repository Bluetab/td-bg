defmodule TdBgWeb.CommentController do
  use TdBgWeb, :controller
  use TdHypermedia, :controller
  use PhoenixSwagger

  alias TdBg.Comments
  alias TdBgWeb.SwaggerDefinitions

  action_fallback(TdBgWeb.FallbackController)

  @available_filters ["resource_id", "resource_type"]

  def swagger_definitions do
    SwaggerDefinitions.comment_swagger_definitions()
  end

  swagger_path :index do
    description("List Comments")
    response(200, "OK", Schema.ref(:CommentsResponse))
  end

  def index(conn, params) do
    comments =
      case Map.take(params, @available_filters) do
        empty when empty == %{} -> Comments.list_comments()
        params_filter -> Comments.list_comments_by_filters(params_filter)
      end

    render(conn, "index.json", comments: comments)
  end

  swagger_path :create do
    description("Creates Comments")
    produces("application/json")

    parameters do
      data_field(:body, Schema.ref(:CommentCreate), "Comment create attrs")
    end

    response(201, "OK", Schema.ref(:CommentResponse))
    response(400, "Client Error")
  end

  def create(conn, %{"comment" => comment_params}) do
    %{user_id: user_id, user_name: user_name} = claims = conn.assigns[:current_resource]

    creation_attrs =
      Map.put(comment_params, "user", %{"user_id" => user_id, "user_name" => user_name})

    with {:ok, %{comment: comment}} <- Comments.create_comment(creation_attrs, claims) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.comment_path(conn, :show, comment))
      |> render("show.json", comment: comment)
    end
  end

  swagger_path :show do
    description("Show Comment")
    produces("application/json")

    parameters do
      id(:path, :integer, "Comment ID", required: true)
    end

    response(200, "OK", Schema.ref(:CommentResponse))
    response(400, "Client Error")
  end

  def show(conn, %{"id" => id}) do
    with {:ok, comment} <- Comments.get_comment(id) do
      render(conn, "show.json", comment: comment)
    end
  end

  swagger_path :delete do
    description("Delete Comment")
    produces("application/json")

    parameters do
      id(:path, :integer, "Comment ID", required: true)
    end

    response(204, "No Content")
    response(400, "Client Error")
  end

  def delete(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]

    with {:ok, comment} <- Comments.get_comment(id),
         {:ok, _} <- Comments.delete_comment(comment, claims) do
      send_resp(conn, :no_content, "")
    end
  end
end
