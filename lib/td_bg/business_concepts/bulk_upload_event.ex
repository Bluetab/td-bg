defmodule TdBg.BusinessConcepts.BulkUploadEvent do
  @moduledoc """
  Ecto Schema module for Business Concepts.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "bulk_upload_events" do
    field(:file_hash, :string)
    field(:filename, :string)
    field(:message, :string)
    field(:node, :string)
    field(:response, :map)
    field(:status, :string)
    field(:task_reference, :string)
    field(:user_id, :integer)

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  @doc false
  def changeset(bulk_upload_event, attrs) do
    bulk_upload_event
    |> cast(attrs, [
      :user_id,
      :response,
      :file_hash,
      :task_reference,
      :status,
      :message,
      :filename
    ])
    |> put_node()
    |> validate_required([:user_id, :file_hash, :filename, :task_reference, :status, :node])
    |> validate_length(:message, max: 10_000)
  end

  defp put_node(changeset) do
    cast(changeset, %{node: Atom.to_string(Node.self())}, [:node])
  end
end
