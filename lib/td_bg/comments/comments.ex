defmodule TdBg.Comments do
  @moduledoc """
  The Comments context.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias TdBg.Comments.Audit
  alias TdBg.Comments.Comment
  alias TdBg.Repo

  @doc """
  Returns the list of comments.

  ## Examples

      iex> list_comments()
      [%Comment{}, ...]

  """
  def list_comments do
    Repo.all(
      from(
        p in Comment,
        order_by: [desc: :inserted_at]
      )
    )
  end

  def filter(params, fields) do
    dynamic = true

    Enum.reduce(Map.keys(params), dynamic, fn x, acc ->
      key_as_atom = String.to_atom(x)

      case Enum.member?(fields, key_as_atom) do
        true -> dynamic([p], field(p, ^key_as_atom) == ^params[x] and ^acc)
        false -> acc
      end
    end)
  end

  def list_comments_by_filters(params) do
    fields = Comment.__schema__(:fields)
    dynamic = filter(params, fields)

    Repo.all(
      from(
        p in Comment,
        where: ^dynamic,
        order_by: [desc: :inserted_at]
      )
    )
  end

  @doc """
  Get a comment. Returns `{:ok, comment}` or `{:error, :not_found}` if the
  comment doesn't exist.

  ## Examples

      iex> get_comment(123)
      {:ok, %Comment{}}

      iex> get_comment(456)
      {:error, :not_found}

  """
  def get_comment(id) do
    case Repo.get(Comment, id) do
      nil -> {:error, :not_found}
      comment -> {:ok, comment}
    end
  end

  @doc """
  Creates a comment and publishes the corresponding audit event.

  ## Examples

      iex> create_comment(%{field: value}, user)
      {:ok, %{audit: "event_id", comment: %Comment{}}}

      iex> create_comment(%{field: bad_value}, user)
      {:error, :comment, %Ecto.Changeset{}, %{}}

  """
  def create_comment(%{} = params, %{id: user_id}) do
    changeset = Comment.changeset(params)

    Multi.new()
    |> Multi.insert(:comment, changeset)
    |> Multi.run(:audit, Audit, :comment_created, [changeset, user_id])
    |> Repo.transaction()
  end

  @doc """
  Deletes a Comment and publishes the corresponding audit event.

  ## Examples

      iex> delete_comment(comment, user)
      {:ok, %{audit: "event_id", comment: %Comment{}}}

      iex> delete_comment(comment, user)
      {:error, :comment, %Ecto.Changeset{}, %{}}

  """
  def delete_comment(%Comment{} = comment, %{id: user_id}) do
    Multi.new()
    |> Multi.delete(:comment, comment)
    |> Multi.run(:audit, Audit, :comment_deleted, [user_id])
    |> Repo.transaction()
  end

  def get_comment_by_resource(resource_type, resource_id) do
    Repo.one(
      from(
        comments in Comment,
        where: comments.resource_type == ^resource_type and comments.resource_id == ^resource_id
      )
    )
  end
end
