defmodule TdBg.Comments.Audit do
  @moduledoc """
  Manages the creation of audit events relating to comments
  """

  import TdBg.Audit.AuditSupport, only: [publish: 4, publish: 5]

  @doc """
  Publishes a `:comment_created` event. Should be called using `Ecto.Multi.run/5`.
  """
  def comment_created(_repo, %{comment: %{id: id}}, %{} = changeset, user_id) do
    publish("comment_created", "comment", id, user_id, changeset)
  end

  @doc """
  Publishes a `:comment_deleted` event. Should be called using `Ecto.Multi.run/5`.
  """
  def comment_deleted(_repo, %{comment: %{id: id}}, user_id) do
    publish("comment_deleted", "comment", id, user_id)
  end
end
