defmodule TdBgWeb.CommentView do
  use TdBgWeb, :view
  alias TdBgWeb.CommentView

  def render("index.json", %{comments: comments}) do
    %{data: render_many(comments, CommentView, "comment.json")}
  end

  def render("show.json", %{comment: comment}) do
    %{data: render_one(comment, CommentView, "comment.json")}
  end

  def render("comment.json", %{comment: comment}) do
    %{id: comment.id,
      resource_id: comment.resource_id,
      resource_type: comment.resource_type,
      created_at: comment.created_at,
      user: comment.user,
      content: comment.content}
  end
end
