defmodule TdBg.BusinessConcepts.BulkUploadEvents do
  @moduledoc """
  The BusinessConcepts context.
  """

  import Ecto.Query

  alias TdBg.BusinessConcepts.BulkUploadEvent
  alias TdBg.Repo

  @doc """
  Returns the list of bulk_upload_events.

  ## Examples

      iex> list_bulk_upload_events()
      [%BulkUploadEvent{}, ...]

  """
  def list_bulk_upload_events do
    Repo.all(BulkUploadEvent)
  end

  def get_by_user_id(user_id) do
    BulkUploadEvent
    |> where([e], e.user_id == ^user_id)
    |> order_by([e], desc: e.user_id, desc: e.file_hash, desc: e.inserted_at)
    |> subquery()
    |> order_by([e], desc: e.inserted_at)
    |> limit(20)
    |> Repo.all()
  end

  @doc """
  Gets a single bulk_upload_event.

  Raises `Ecto.NoResultsError` if the Bulk upload event does not exist.

  ## Examples

      iex> get_bulk_upload_event!(123)
      %BulkUploadEvent{}

      iex> get_bulk_upload_event!(456)
      ** (Ecto.NoResultsError)

  """
  def get_bulk_upload_event!(id), do: Repo.get!(BulkUploadEvent, id)

  @doc """
  Creates a bulk_upload_event.

  ## Examples

      iex> create_bulk_upload_event(%{field: value})
      {:ok, %BulkUploadEvent{}}

      iex> create_bulk_upload_event(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bulk_upload_event(attrs \\ %{}) do
    %BulkUploadEvent{}
    |> BulkUploadEvent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a bulk_upload_event.

  ## Examples

      iex> update_bulk_upload_event(bulk_upload_event, %{field: new_value})
      {:ok, %BulkUploadEvent{}}

      iex> update_bulk_upload_event(bulk_upload_event, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_bulk_upload_event(%BulkUploadEvent{} = bulk_upload_event, attrs) do
    bulk_upload_event
    |> BulkUploadEvent.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a bulk_upload_event.

  ## Examples

      iex> delete_bulk_upload_event(bulk_upload_event)
      {:ok, %BulkUploadEvent{}}

      iex> delete_bulk_upload_event(bulk_upload_event)
      {:error, %Ecto.Changeset{}}

  """
  def delete_bulk_upload_event(%BulkUploadEvent{} = bulk_upload_event) do
    Repo.delete(bulk_upload_event)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking bulk_upload_event changes.

  ## Examples

      iex> change_bulk_upload_event(bulk_upload_event)
      %Ecto.Changeset{data: %BulkUploadEvent{}}

  """
  def change_bulk_upload_event(%BulkUploadEvent{} = bulk_upload_event, attrs \\ %{}) do
    BulkUploadEvent.changeset(bulk_upload_event, attrs)
  end

  def last_event_by_hash(hash) do
    BulkUploadEvent
    |> where([e], e.file_hash == ^hash)
    |> order_by([e], desc: e.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  def event_started_and_not_finished do
    started_events_query =
      from(started_events in BulkUploadEvent,
        as: :started_events,
        where: started_events.status == "STARTED"
      )

    subquery =
      from(f in BulkUploadEvent,
        select: f.file_hash,
        where: f.status in ^["COMPLETED", "FAILED"],
        where: f.inserted_at > parent_as(:started_events).inserted_at,
        where: f.file_hash == parent_as(:started_events).file_hash
      )

    query = from(se in started_events_query, where: fragment("NOT EXISTS ?", subquery(subquery)))

    Repo.all(query)
  end
end
