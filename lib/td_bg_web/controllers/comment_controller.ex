defmodule TdBgWeb.CommentController do
  use TdBgWeb, :controller
  use TdBg.Hypermedia, :controller
  use PhoenixSwagger

  alias TdBg.Comments
  alias TdBg.Comments.Comment
  alias TdBg.Comments.Events
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
    current_user = conn.assigns[:current_user]

    creation_attrs =
      comment_params
      |> Map.put("user", %{
        "user_id" => current_user.id,
        "full_name" => current_user.full_name,
        "user_name" => current_user.user_name
      })
      |> is_timestamp_informed?

    with {:ok, %Comment{} = comment} <- Comments.create_comment(creation_attrs) do
      Events.comment_created(comment.id, comment_params, conn.assigns[:current_user])

      conn
      |> put_status(:created)
      |> put_resp_header("location", comment_path(conn, :show, comment))
      |> render("show.json", comment: comment)
    end
  end

  defp is_timestamp_informed?(comment_params) do
    if Map.has_key?(comment_params, "created_at"),
      do: comment_params,
      else: Map.put(comment_params, "created_at", DateTime.utc_now())
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
    comment = Comments.get_comment!(id)
    render(conn, "show.json", comment: comment)
  end

  swagger_path :update do
    description("Update Comments")
    produces("application/json")

    parameters do
      id(:path, :integer, "Comment ID", required: true)
      comment(:body, Schema.ref(:CommentUpdate), "Comment update attrs")
    end

    response(201, "OK", Schema.ref(:CommentResponse))
    response(400, "Client Error")
  end

  def update(conn, %{"id" => id, "comment" => comment_params}) do
    comment = Comments.get_comment!(id)

    with {:ok, %Comment{} = comment} <- Comments.update_comment(comment, comment_params) do
      Events.comment_updated(id, comment_params, conn.assigns[:current_user])
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
    comment = Comments.get_comment!(id)

    with {:ok, %Comment{}} <- Comments.delete_comment(comment) do
      Events.comment_deleted(id, conn.assigns[:current_user])
      send_resp(conn, :no_content, "")
    end
  end
end
