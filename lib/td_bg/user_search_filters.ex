defmodule TdBg.UserSearchFilters do
  @moduledoc """
  The UserSearchFilters context.
  """

  import Ecto.Query, warn: false

  alias TdBg.Repo
  alias TdBg.UserSearchFilters.UserSearchFilter
  alias TdCache.Permissions

  @doc """
  Returns the list of user_search_filters.

  ## Examples

      iex> list_user_search_filters()
      [%UserSearchFilter{}, ...]

  """
  def list_user_search_filters do
    Repo.all(UserSearchFilter)
  end

  @doc """
  Returns the list of user_search_filters for the given user.

  ## Examples

      iex> list_user_search_filters(1)
      [%UserSearchFilter{}, ...]

  """
  def list_user_search_filters(%{user_id: user_id} = claims) do
    UserSearchFilter
    |> where([usf], usf.is_global or usf.user_id == ^user_id)
    |> Repo.all()
    |> maybe_filter(claims)
  end

  defp maybe_filter(results, %{role: "admin"}), do: results

  defp maybe_filter(results, %{jti: jti}) do
    case Permissions.permitted_domain_ids(jti, "view_published_business_concepts") do
      [] ->
        if Permissions.default_permission?("view_published_business_concepts"),
          do: results,
          else: []

      domain_ids ->
        Enum.reject(results, fn
          %{filters: %{"taxonomy" => taxonomy}} ->
            MapSet.disjoint?(MapSet.new(taxonomy), MapSet.new(domain_ids))

          _ ->
            false
        end)
    end
  end

  defp maybe_filter(_results, _claims), do: []

  @doc """
  Gets a single user_search_filter.

  Raises `Ecto.NoResultsError` if the User search filter does not exist.

  ## Examples

      iex> get_user_search_filter!(123)
      %UserSearchFilter{}

      iex> get_user_search_filter!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_search_filter!(id), do: Repo.get!(UserSearchFilter, id)

  @doc """
  Creates a user_search_filter.

  ## Examples

      iex> create_user_search_filter(%{field: value})
      {:ok, %UserSearchFilter{}}

      iex> create_user_search_filter(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_search_filter(attrs \\ %{}) do
    %UserSearchFilter{}
    |> UserSearchFilter.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a user_search_filter.

  ## Examples

      iex> delete_user_search_filter(user_search_filter)
      {:ok, %UserSearchFilter{}}

      iex> delete_user_search_filter(user_search_filter)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_search_filter(%UserSearchFilter{} = user_search_filter) do
    Repo.delete(user_search_filter)
  end
end
