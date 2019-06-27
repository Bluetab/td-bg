defmodule TdBg.Comments.Events do
  @moduledoc """
  Manages the creation of audit events relating to comments
  """

  alias TdBg.Audit
  alias TdBg.Cache.ConceptLoader
  alias TdBg.Comments.Comment

  def comment_created(%Comment{id: id} = comment, payload, user) do
    publish_event_stream(comment)

    %{resource_id: id, resource_type: :comment, payload: payload}
    |> publish_event(:create_comment, user)
  end

  def comment_updated(%Comment{id: id}, payload, user) do
    %{resource_id: id, resource_type: :comment, payload: payload}
    |> publish_event(:update_comment, user)
  end

  def comment_deleted(%Comment{id: id}, user) do
    %{resource_id: id, resource_type: :comment, payload: %{}}
    |> publish_event(:delete_comment, user)
  end

  defp publish_event_stream(%Comment{
         resource_type: "business_concept",
         resource_id: business_concept_id
       }) do
    ConceptLoader.refresh(business_concept_id)
    # TODO: Publish event to event stream, consume in td-audit
  end

  defp publish_event(event_params, event, %{id: user_id, user_name: user_name}) do
    event_params
    |> Map.put(:event, event)
    |> Map.put(:user_id, user_id)
    |> Map.put(:user_name, user_name)
    |> Audit.publish_event()
  end
end
