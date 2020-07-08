defmodule TdBg.Taxonomies do
  @moduledoc """
  The Taxonomies context.
  """

  import Ecto.Query

  alias Ecto.Changeset
  alias Ecto.Multi
  alias TdBg.BusinessConcept.Search
  alias TdBg.Cache.DomainLoader
  alias TdBg.Groups
  alias TdBg.Groups.DomainGroup
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
  def get_domain!(id, preload \\ []) do
    Domain
    |> where([d], d.id == ^id and is_nil(d.deleted_at))
    |> Repo.one!()
    |> with_preloads(preload)
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

  def get_domain_by_name(name, preload \\ []) do
    Domain
    |> where([d], d.name == ^name)
    |> where([d], is_nil(d.deleted_at))
    |> Repo.one()
    |> with_preloads(preload)
  end

  defp with_preloads(%Domain{} = domain, []), do: domain

  defp with_preloads(%Domain{} = domain, preload), do: Repo.preload(domain, preload)

  defp with_preloads(result, _preload), do: result

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
    attrs = with_domain_group(attrs)
    changeset = Domain.changeset(%Domain{}, attrs)

    result =
      Multi.new()
      |> Multi.run(:domain_group, fn _, _ -> group_on_create(changeset, attrs) end)
      |> Multi.insert(:domain, &Domain.put_group(changeset, &1))
      |> Repo.transaction()

    case result do
      {:ok, %{domain: domain}} ->
        DomainLoader.refresh(domain.id)
        get_domain(domain.id)

      {:error, _, changeset, _} ->
        {:error, changeset}
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
    attrs = with_domain_group(attrs)
    domain = Repo.preload(domain, [:domain_group, :parent])
    changeset = Domain.changeset(domain, attrs)

    Multi.new()
    |> Multi.run(:domain_group, fn _, _ -> group_on_update(domain, changeset, attrs) end)
    |> Multi.run(:descendents, fn _, changes -> valid_descendents(changes, domain) end)
    |> Multi.update(:domain, &put_group(domain, changeset, &1))
    |> Multi.run(:children, fn _, changes -> update_children_groups(changes) end)
    |> Repo.transaction()
    |> refresh_cache()
  end

  defp refresh_cache({:ok, %{domain: %Domain{} = domain}}) do
    DomainLoader.refresh(:all)
    IndexWorker.reindex(:all)
    {:ok, domain}
  end

  defp refresh_cache({:error, _, changeset, _}), do: {:error, changeset}

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

  defp with_domain_group(%{"domain_group" => domain_group} = attrs) do
    attrs
    |> Map.put(:domain_group, domain_group)
    |> Map.delete("domain_group")
  end

  defp with_domain_group(attrs), do: attrs

  defp group_on_create(_changeset, %{domain_group: domain_group}) do
    create_group(domain_group)
  end

  defp group_on_create(%{changes: %{parent_id: parent_id}}, _attrs) when not is_nil(parent_id) do
    case get_domain(parent_id) do
      {:ok, %Domain{domain_group_id: nil}} ->
        {:ok, nil}

      {:ok, %Domain{domain_group_id: domain_group_id}} ->
        {:ok, Groups.get_domain_group(domain_group_id)}

      _ ->
        {:ok, nil}
    end
  end

  defp group_on_create(_changeset, _attrs), do: {:ok, nil}

  defp group_on_update(_domain, _changeset, %{domain_group: domain_group}) do
    case create_group(domain_group) do
      {:ok, nil} -> {:ok, %{domain_group: domain_group, status: :deleted}}
      {:ok, %DomainGroup{} = domain_group} -> {:ok, %{domain_group: domain_group, status: :updated}}
      error -> error
    end
  end

  defp group_on_update(%Domain{domain_group_id: nil}, %{changes: %{parent_id: parent_id}}, _attrs) do
    {:ok, %{domain_group: get_domain_group(parent_id), status: :inherited}}
  end

  defp group_on_update(
         %Domain{domain_group_id: domain_group_id, parent: %{domain_group_id: parent_group_id}},
         %{changes: %{parent_id: parent_id}},
         _attrs
       )
       when domain_group_id == parent_group_id do
    {:ok, %{domain_group: get_domain_group(parent_id), status: :inherited}}
  end

  defp group_on_update(%Domain{domain_group: domain_group}, _changeset, _attrs),
    do: {:ok, %{domain_group: domain_group, status: :unchanged}}

  defp get_domain_group(nil), do: nil

  defp get_domain_group(domain_id) do
    domain_group =
      domain_id
      |> get_domain!()
      |> Repo.preload(:domain_group)
      |> Map.get(:domain_group)

    domain_group
  end

  defp create_group(nil), do: {:ok, nil}

  defp create_group(name) do
    case Groups.get_by(name: name) do
      nil -> Groups.create_domain_group(%{name: name})
      domain_group -> {:ok, domain_group}
    end
  end

  defp valid_descendents(%{domain_group: %{status: status}}, _domain)
       when status in [:unchanged, :deleted] do
    {:ok, []}
  end

  defp valid_descendents(_changes, %Domain{id: domain_id, domain_group: domain_group}) do
    prev_domain_group_id = Map.get(domain_group || %{}, :id)

    descendants =
      domain_id
      |> descendent_ids()
      |> Enum.reject(&(&1 == domain_id))
      |> children_by_group(prev_domain_group_id)

    {:ok, descendants}
  end

  defp put_group(_domain, changeset, %{domain_group: %{status: :unchanged}}), do: changeset

  defp put_group(domain, changeset, %{domain_group: domain_group, descendents: descendents}) do
    Domain.put_group(domain, changeset, Map.merge(domain_group, %{descendents: descendents}))
  end

  defp update_children_groups(%{
         domain: %{domain_group_id: domain_group_id},
         descendents: descendents
       }) do
    updated =
      descendents
      |> Enum.map(&Domain.changeset(&1, %{domain_group_id: domain_group_id}))
      |> Enum.map(&Repo.update/1)

    case Enum.find(updated, &(elem(&1, 0) == :error)) do
      nil -> {:ok, updated}
      error -> error
    end
  end

  defp children_by_group([], _), do: []

  defp children_by_group(descendents, domain_group_id) do
    Domain
    |> where([d], is_nil(d.deleted_at))
    |> where([d], d.id in ^descendents)
    |> group_id_condition(domain_group_id)
    |> Repo.all()
  end

  defp group_id_condition(query, nil) do
    where(query, [d], is_nil(d.domain_group_id))
  end

  defp group_id_condition(query, domain_group_id) do
    where(query, [d], is_nil(d.domain_group_id) or d.domain_group_id == ^domain_group_id)
  end

  @doc """
  Returns the list of domain ids which are descendents of a given `domain_id`,
  including itself.
  """
  defdelegate descendent_ids(domain_id), to: __MODULE__.Tree
end
