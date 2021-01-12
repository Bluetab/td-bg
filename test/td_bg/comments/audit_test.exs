defmodule TdBg.Comments.AuditTest do
  use TdBg.DataCase

  alias TdBg.Comments.Audit
  alias TdBg.Comments.Comment
  alias TdBg.Repo
  alias TdCache.Redix
  alias TdCache.Redix.Stream

  @stream TdCache.Audit.stream()

  setup_all do
    Redix.del!(@stream)
    :ok
  end

  setup do
    on_exit(fn -> Redix.del!(@stream) end)

    session = build(:session, role: "admin")
    [session: session, comment: insert(:comment)]
  end

  describe "comment_created/4" do
    test "publishes an event", %{
      comment: %{id: comment_id} = comment,
      session: %{user_id: user_id}
    } do
      %{
        "content" => content,
        "resource_type" => resource_type,
        "resource_id" => resource_id,
        "user" => user
      } = params = string_params_for(:comment)

      changeset = Comment.changeset(params)

      assert {:ok, event_id} =
               Audit.comment_created(Repo, %{comment: comment}, changeset, user_id)

      assert {:ok, [event]} = Stream.range(:redix, @stream, event_id, event_id, transform: :range)

      user_id = "#{user_id}"
      comment_id = "#{comment_id}"

      assert %{
               event: "comment_created",
               payload: payload,
               resource_id: ^comment_id,
               resource_type: "comment",
               service: "td_bg",
               ts: _ts,
               user_id: ^user_id
             } = event

      assert %{
               "content" => ^content,
               "resource_id" => ^resource_id,
               "resource_type" => ^resource_type,
               "user" => ^user
             } = Jason.decode!(payload)
    end
  end

  describe "comment_deleted/3" do
    test "publishes an event", %{session: %{user_id: user_id}} do
      %{id: comment_id} = comment = insert(:comment)

      assert {:ok, event_id} = Audit.comment_deleted(Repo, %{comment: comment}, user_id)
      assert {:ok, [event]} = Stream.range(:redix, @stream, event_id, event_id, transform: :range)

      user_id = "#{user_id}"
      resource_id = "#{comment_id}"

      assert %{
               event: "comment_deleted",
               payload: "{}",
               resource_id: ^resource_id,
               resource_type: "comment",
               service: "td_bg",
               ts: _ts,
               user_id: ^user_id
             } = event
    end
  end
end
