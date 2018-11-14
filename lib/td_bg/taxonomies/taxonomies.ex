defmodule TdBg.Taxonomies do
  @moduledoc """
  The Taxonomies context.
  """

  import Ecto.Query, warn: false
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.DomainLoader
  alias TdBg.Repo
  alias TdBg.Taxonomies.Domain

  @doc """
  Returns the list of domains.

  ## Examples

      iex> list_domains()
      [%Domain{}, ...]

  """
  def list_domains do
    query = from(d in Domain)

    query
    |> Repo.all()
  end

  @doc """
  Returns the list of root domains (no parent)
  """
  def list_root_domains do
    Repo.all(from(r in Domain, where: is_nil(r.parent_id)))
  end

  @doc """
  Returns children of domain id passed as argument
  """
  def count_domain_children(id) do
    count = Repo.one(from(r in Domain, select: count(r.id), where: r.parent_id == ^id))
    {:count, :domain, count}
  end

  @doc """
  Returns a count of the existing domains with the same name and which
  haven't been deleted
  """
  def count_domain_by_name(name, domain_id) do
    count =
      Domain
        |> count_domain_by_name_where_clause(name, domain_id)
        |> select([r], count(r.id))
        |> Repo.one()

    {:count, :domain, count}
  end

  defp count_domain_by_name_where_clause(query, name, nil) do
    query |> where([r], r.name == ^name and is_nil(r.deleted_at))
  end

  defp count_domain_by_name_where_clause(query, name, domain_id) do
    query |> where([r], r.name == ^name and is_nil(r.deleted_at) and r.id != ^domain_id)
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
    Repo.one!(from(r in Domain, where: r.id == ^id))
  end

  def get_domain(id) do
    Repo.one(from(r in Domain, where: r.id == ^id))
  end

  def get_domain_by_name(name) do
    Repo.one(from(r in Domain, where: r.name == ^name))
  end

  def get_children_domains(%Domain{} = domain) do
    id = domain.id
    Repo.all(from(r in Domain, where: r.parent_id == ^id))
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
        {:ok, get_domain!(domain.id)}
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
  end

  @doc """
  Soft deletion of a domain.

  ## Examples

      iex> delete_domain(domain)
      {:ok, %Domain{}}

      iex> delete_domain(domain)
      {:error, %Ecto.Changeset{}}

  """
  def delete_domain(%Domain{id: id} = domain) do
    updated_domain =
      domain
      |> Domain.delete_changeset()
      |> Repo.update()

    case updated_domain do
      {:ok, struct} ->
        DomainLoader.delete(id)
        {:ok, struct}
      error -> error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking domain changes.

  ## Examples

      iex> change_domain(domain)
      %Ecto.Changeset{source: %Domain{}}

  """
  def change_domain(%Domain{} = domain) do
    Domain.changeset(domain, %{})
  end

  @doc """
  Obtain the ancestors of a given domain. If the second parameter is true,
  the domain itself will be included in the list of ancestors.
  """
  def get_domain_ancestors(nil, _), do: []
  def get_domain_ancestors(domain, false) do
    get_ancestors_for_domain_id(domain.parent_id, true)
  end
  def get_domain_ancestors(domain, true) do
    [domain | get_ancestors_for_domain_id(domain.parent_id, true)]
  end

  def get_ancestors_for_domain_id(domain_id, with_self \\ true)
  def get_ancestors_for_domain_id(nil, _), do: []
  def get_ancestors_for_domain_id(domain_id, with_self) do
    domain = get_domain(domain_id)
    get_domain_ancestors(domain, with_self)
  end

  def get_parent_id(nil) do
    {:error, nil}
  end

  def get_parent_id(%{parent_id: nil}) do
    {:ok, nil}
  end

  def get_parent_id(%{parent_id: parent_id}) do
    get_parent_id(get_domain(parent_id))
  end

  def get_parent_id(parent_id) do
    {:ok, parent_id}
  end

  def count_domain_business_concept_children(id) do
    query =
      from(b in BusinessConcept,
        where: b.domain_id == ^id,
        join: bv in BusinessConceptVersion,
        where: b.id == bv.business_concept_id and bv.status != "deprecated",
        select: count(b.id)
      )

      count = query |> Repo.one()
    {:count, :business_concept, count}
  end

  @doc """
    Returns map of taxonomy tree structure
  """
  def tree do
    d_list = list_root_domains() |> Enum.sort(&(&1.name < &2.name))
    d_all = list_domains() |> Enum.sort(&(&1.name < &2.name))
    Enum.map(d_list, fn d -> build_node(d, d_all) end)
  end

  defp build_node(%Domain{} = d, d_all) do
    Map.merge(d, %{children: list_children(d, d_all)})
  end

  defp list_children(%Domain{} = node, d_all) do
    d_children = Enum.filter(d_all, fn d -> node.id == d.parent_id end)

    if d_children do
      Enum.map(d_children, fn d -> build_node(d, d_all) end)
    else
      []
    end
  end
end
