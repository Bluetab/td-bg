defmodule TdBg.CommentsTest do
  use TdBg.DataCase

  alias TdBg.Comments
  alias TdCache.Redix
  alias TdCache.Redix.Stream

  @stream TdCache.Audit.stream()

  setup_all do
    Redix.del!(@stream)
    :ok
  end

  setup do
    on_exit(fn -> Redix.del!(@stream) end)

    user = build(:user, is_admin: true)
    [user: user]
  end

  describe "create_comment/2" do
    test "creates a comment and publishes an event to the audit stream", %{user: user} do
      params = string_params_for(:comment)
      assert {:ok, %{comment: comment, audit: event_id}} = Comments.create_comment(params, user)
      assert {:ok, [%{id: ^event_id}]} = Stream.read(:redix, @stream, transform: true)
    end
  end

  describe "delete_comment/2" do
    test "deletes a comment and publishes an event to the audit stream", %{user: user} do
      comment = insert(:comment)
      assert {:ok, %{comment: comment, audit: event_id}} = Comments.delete_comment(comment, user)
      assert {:ok, [%{id: ^event_id}]} = Stream.read(:redix, @stream, transform: true)
    end
  end
end
