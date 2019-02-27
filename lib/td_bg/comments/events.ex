defmodule TdBg.Comments.Events do
  @moduledoc """
  Manages the creation of audit events relating to comments
  """

  alias TdBg.Audit

  def comment_created(id, payload, user) do
    %{resource_id: id, resource_type: :comment, payload: payload}
    |> publish_event(:create_comment, user)
  end

  def comment_updated(id, payload, user) do
    %{resource_id: id, resource_type: :comment, payload: payload}
    |> publish_event(:update_comment, user)
  end

  def comment_deleted(id, user) do
    %{resource_id: id, resource_type: :comment, payload: %{}}
    |> publish_event(:delete_comment, user)
  end

  defp publish_event(event_params, event, %{id: user_id, user_name: user_name}) do
    event_params
    |> Map.put(:event, event)
    |> Map.put(:user_id, user_id)
    |> Map.put(:user_name, user_name)
    |> Audit.publish_event()
  end
end
