defmodule TdBg.Taxonomies do
  @moduledoc """
  The Taxonomies context.
  """

  import Ecto.Query

  alias Ecto.Changeset
  alias TdBg.BusinessConcept.Search
  alias TdBg.Cache.DomainLoader
  alias TdBg.Repo
  alias TdBg.Search.IndexWorker
  alias TdBg.Taxonomies.Domain
  alias TdCache.TaxonomyCache

  @doc """
  Returns the list of domains.

  ## Examples

      iex> list_domains()
      [%Domain{}, ...]

  """
  def list_domains do
    query = from(d in Domain)

    query
    |> where([d], is_nil(d.deleted_at))
    |> Repo.all()
  end

  @doc """
  Returns the list of root domains (no parent)
  """
  def list_root_domains do
    Repo.all(from(r in Domain, where: is_nil(r.parent_id)))
  end

  @doc """
  Returns count of domains applying clauses dynamically
  """
  def count(clauses) do
    clauses
    |> Enum.reduce(Domain, fn
      {:deleted_at, nil}, q -> where(q, [d], is_nil(d.deleted_at))
      {:parent_id, parent_id}, q -> where(q, [d], d.parent_id == ^parent_id)
    end)
    |> select([_], count())
    |> Repo.one!()
  end

  @doc """
  Gets a single domain.

  Raises `Ecto.NoResultsError` if the Domain does not exist.

  ## Examples

      iex> get_domain!(123)
      %Domain{}

      iex> get_domain!(456)
      ** (Ecto.NoResultsError)

  """
  def get_domain!(id) do
    Repo.one!(from(r in Domain, where: r.id == ^id and is_nil(r.deleted_at)))
  end

  def get_domain(id) do
    Domain
    |> where([d], d.id == ^id and is_nil(d.deleted_at))
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      domain -> {:ok, domain}
    end
  end

  def get_parent_ids(nil), do: []
  def get_parent_ids(id), do: TaxonomyCache.get_parent_ids(id)

  def get_domain_by_name(name) do
    Repo.one(from(r in Domain, where: r.name == ^name and is_nil(r.deleted_at)))
  end

  def get_children_domains(%Domain{} = domain) do
    id = domain.id
    Repo.all(from(r in Domain, where: r.parent_id == ^id and is_nil(r.deleted_at)))
  end

  def count_existing_users_with_roles(domain_id, user_name) do
    predefined_query = %{
      bool: %{
        must_not: %{
          term: %{status: "deprecated"}
        },
        must: %{
          query_string: %{
            query: "content.\\*:(\"#{user_name |> String.downcase()}\")"
          }
        },
        filter: [%{term: %{current: true}}, %{term: %{domain_ids: domain_id}}]
      }
    }

    predefined_query
    |> Search.get_business_concepts_from_query(0, 10_000)
    |> Map.get(:results)
    |> length()
  end

  @doc """
  Creates a domain.

  ## Examples

      iex> create_domain(%{field: value})
      {:ok, %Domain{}}

      iex> create_domain(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_domain(attrs \\ %{}) do
    result =
      %Domain{}
      |> Domain.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, domain} ->
        DomainLoader.refresh(domain.id)
        get_domain(domain.id)

      _ ->
        result
    end
  end

  @doc """
  Updates a domain.

  ## Examples

      iex> update_domain(domain, %{field: new_value})
      {:ok, %Domain{}}

      iex> update_domain(domain, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_domain(%Domain{} = domain, attrs) do
    domain
    |> Domain.changeset(attrs)
    |> Repo.update()
    |> refresh_cache()
  end

  defp refresh_cache({:ok, %Domain{}} = response) do
    DomainLoader.refresh(:all)
    IndexWorker.reindex(:all)
    response
  end

  defp refresh_cache(error), do: error

  @doc """
  Soft deletion of a domain.

  ## Examples

      iex> delete_domain(domain)
      {:ok, %Domain{}}

      iex> delete_domain(domain)
      {:error, %Ecto.Changeset{}}

  """
  def delete_domain(%Domain{id: id} = domain) do
    changeset = Domain.delete_changeset(domain)

    with {:domains, 0} <- {:domains, count(parent_id: id, deleted_at: nil)},
         {:concepts, 0} <- {:concepts, current_concept_count(domain)},
         {:ok, domain} <- Repo.update(changeset) do
      DomainLoader.delete(id)
      {:ok, domain}
    else
      {:domains, _} ->
        {:error, Changeset.add_error(changeset, :domain, "existing.domain", code: "ETD001")}

      {:concepts, _} ->
        {:error,
         Changeset.add_error(changeset, :domain, "existing.business.concept", code: "ETD002")}
    end
  end

  defp current_concept_count(%Domain{id: id}) do
    TdBg.BusinessConcepts.count(domain_id: id, deprecated: false)
  end

  @doc """
  Returns a domain with changes applied, ignoring validations. Note that changes
  are not persisted to the Repo. See `Changeset.apply_changes/1`.
  """
  def apply_changes(%Domain{} = domain, %{} = params) do
    domain
    |> Domain.changeset(params)
    |> Changeset.apply_changes()
  end

  def apply_changes(Domain, %{} = params) do
    params
    |> Domain.changeset()
    |> Changeset.apply_changes()
  end

  @doc """
  Returns the list of domain ids to which a user can move a domain. Note that a
  domain's parent cannot be itself or any descendent domain.

  In order to move a domain, the user must have permissions `:delete_domain` and
  `:update_domain` on the domain to move, and `:create_domain` on the new parent
  domain.
  """
  def get_parentable_ids(user, %Domain{id: id} = domain) do
    import Canada, only: [can?: 2]

    if can?(user, move(domain)) do
      descendent_ids = descendent_ids(id)

      list_domains()
      |> Enum.reject(&Enum.member?(descendent_ids, &1.id))
      |> Enum.filter(&can?(user, create(&1)))
      |> Enum.map(& &1.id)
    else
      []
    end
  end

  @doc """
  Returns the list of domain ids which are descendents of a given `domain_id`,
  including itself.
  """
  defdelegate descendent_ids(domain_id), to: __MODULE__.Tree
end
