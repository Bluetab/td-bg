defmodule TdBg.BusinessConcepts do
  @moduledoc """
  The BusinessConcepts context.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias TdBg.Auth.Claims
  alias TdBg.BusinessConcepts.Audit
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Cache.ConceptLoader
  alias TdBg.Repo
  alias TdBg.Search.Indexer
  alias TdCache.ConceptCache
  alias TdCache.EventStream.Publisher
  alias TdCache.TemplateCache
  alias TdDfLib.Format
  alias TdDfLib.Templates
  alias TdDfLib.Validation
  alias ValidationError

  @doc """
  check business concept name availability
  """
  def check_business_concept_name_availability(type, name, opts \\ [])

  def check_business_concept_name_availability(type, name, _opts)
      when is_nil(name) or is_nil(type),
      do: :ok

  def check_business_concept_name_availability(type, name, opts) do
    status = ["versioned", "deprecated"]

    BusinessConcept
    |> join(:left, [c], _ in assoc(c, :versions))
    |> join(:left, [c, _v], _ in assoc(c, :domain))
    |> where([c, v, _d], c.type == ^type and v.status not in ^status)
    |> include_name_where(name, Keyword.get(opts, :business_concept_id))
    |> with_group_clause(Keyword.get(opts, :domain_group_id))
    |> select([c, v], count(c.id))
    |> Repo.one!()
    |> case do
      0 -> :ok
      _ -> {:error, :name_not_available}
    end
  end

  defp include_name_where(query, name, nil) do
    where(query, [_, v, _d], fragment("lower(?)", v.name) == ^String.downcase(name))
  end

  defp include_name_where(query, name, exclude_concept_id) do
    where(
      query,
      [c, v, _d],
      c.id != ^exclude_concept_id and fragment("lower(?)", v.name) == ^String.downcase(name)
    )
  end

  def get_active_concepts_in_group(group_id) do
    BusinessConcept
    |> join(:left, [c], _ in assoc(c, :versions))
    |> join(:left, [c, _v], _ in assoc(c, :domain))
    |> with_group_clause(group_id)
    |> where([_c, v, _d], v.status not in ^["versioned", "deprecated"])
    |> distinct([_c, v, d], [v.name, d.id])
    |> select([c, v, _d], %{v | business_concept: c})
    |> Repo.all()
  end

  def get_active_concepts_by_domain_ids([]), do: []

  def get_active_concepts_by_domain_ids(domain_ids) do
    BusinessConcept
    |> join(:left, [c], _ in assoc(c, :versions))
    |> join(:left, [c, _v], _ in assoc(c, :domain))
    |> where([_c, _v, d], d.id in ^domain_ids)
    |> where([_c, v, _d], v.status not in ^["versioned", "deprecated"])
    |> distinct([_c, v, d], [v.name, d.id])
    |> select([c, v, _d], %{v | business_concept: c})
    |> Repo.all()
  end

  defp with_group_clause(query, nil) do
    where(query, [_c, _v, d], is_nil(d.domain_group_id))
  end

  defp with_group_clause(query, group_id) do
    where(query, [_c, _v, d], d.domain_group_id == ^group_id)
  end

  @doc """
  list all business concepts
  """
  def list_all_business_concepts do
    BusinessConcept
    |> Repo.all()
  end

  @doc """
  Fetch an exsisting business_concept by its id
  """
  def get_business_concept!(business_concept_id) do
    BusinessConcept
    |> where([c], c.id == ^business_concept_id)
    |> Repo.one!()
  end

  @doc """
  count published business concepts
  business concept must be of indicated type
  business concept are resticted to indicated id list
  """
  def count_published_business_concepts(type, ids) do
    BusinessConcept
    |> join(:left, [c], _ in assoc(c, :versions))
    |> where([c, v], c.type == ^type and c.id in ^ids and v.status == "published")
    |> select([c, _v], count(c.id))
    |> Repo.one!()
  end

  @doc """
  Returns children of domain id passed as argument
  """
  def get_domain_children_versions!(domain_id) do
    BusinessConceptVersion
    |> join(:left, [v], _ in assoc(v, :business_concept))
    |> preload([_, c], business_concept: c)
    |> where([_, c], c.domain_id == ^domain_id)
    |> Repo.all()
  end

  def get_all_versions_by_business_concept_ids([]), do: []

  def get_all_versions_by_business_concept_ids(business_concept_ids) do
    BusinessConceptVersion
    |> where([v], v.business_concept_id in ^business_concept_ids)
    |> preload(:business_concept)
    |> Repo.all()
  end

  def get_active_ids do
    BusinessConceptVersion
    |> where([v], v.current == true)
    |> where([v], v.status != "deprecated")
    |> select([v], v.business_concept_id)
    |> Repo.all()
  end

  def get_confidential_ids do
    BusinessConceptVersion
    |> join(:inner, [v, c], c in BusinessConcept, on: v.business_concept_id == c.id)
    |> where([v, _], v.current == true)
    |> where([v, _], v.status != "deprecated")
    |> where([_, c], c.confidential == true)
    |> select([v, _], v.business_concept_id)
    |> Repo.all()
  end

  @doc """
  Gets a single business concept version.

  Raises `Ecto.NoResultsError` if the Business concept does not exist.

  ## Examples

      iex> get_last_version_by_business_concept_id!(123)
      %BusinessConceptVersion{}

      iex> get_last_version_by_business_concept_id!(456)
      ** (Ecto.NoResultsError)

  """
  def get_last_version_by_business_concept_id!(business_concept_id) do
    BusinessConceptVersion
    |> where([v], v.business_concept_id == ^business_concept_id)
    |> order_by(desc: :version)
    |> limit(1)
    |> preload(business_concept: :domain)
    |> Repo.one!()
  end

  def last?(%BusinessConceptVersion{id: id, business_concept_id: business_concept_id}) do
    get_last_version_by_business_concept_id!(business_concept_id).id == id
  end

  @doc """
  Gets a single business_concept searching for the published version instead of the latest.

  Raises `Ecto.NoResultsError` if the Business concept does not exist.

  ## Examples

      iex> get_currently_published_version!(123)
      %BusinessConcept{}

      iex> get_currently_published_version!(456)
      ** (Ecto.NoResultsError)

  """
  def get_currently_published_version!(business_concept_id) do
    version =
      BusinessConceptVersion
      |> where([v], v.business_concept_id == ^business_concept_id)
      |> where([v], v.status == "published")
      |> preload(business_concept: [:domain])
      |> Repo.one()

    case version do
      nil -> get_last_version_by_business_concept_id!(business_concept_id)
      _ -> version
    end
  end

  @doc """
  Creates a business_concept and publishes the corresponding audit event. If the
  `:index` option is set to `true`, the concept will be reindexed on successful
  creation.

  ## Examples

      iex> create_business_concept(%{field: value}, index: true)
      {:ok, %BusinessConceptVersion{}}

      iex> create_business_concept(%{field: bad_value})
      {:error, %Changeset{}}

  """
  def create_business_concept(params, opts \\ []) do
    params
    |> attrs_keys_to_atoms()
    |> raise_error_if_no_content_schema()
    |> format_content()
    |> set_content_defaults()
    |> validate_new_concept()
    |> validate_description()
    |> validate_concept_content(opts[:in_progress])
    |> insert_concept()
    |> index_on_success(opts[:index])
  end

  defp index_on_success({:ok, %{} = res}, true) do
    with %{business_concept_version: %{id: id}} <- res do
      %{business_concept_id: business_concept_id} = bcv = get_business_concept_version!(id)
      ConceptLoader.refresh(business_concept_id)
      {:ok, bcv}
    end
  end

  defp index_on_success(result, _), do: result

  defp format_content(%{content: content} = params) when not is_nil(content) do
    content =
      params
      |> Map.get(:content_schema)
      |> Enum.filter(fn %{"type" => schema_type, "cardinality" => cardinality} ->
        schema_type in ["url", "enriched_text"] or
          (schema_type in ["string", "user"] and cardinality in ["*", "+"])
      end)
      |> Enum.filter(fn %{"name" => name} ->
        field_content = Map.get(content, name)
        not is_nil(field_content) and is_binary(field_content) and field_content != ""
      end)
      |> Enum.into(
        content,
        &format_field(&1, content)
      )

    Map.put(params, :content, content)
  end

  defp format_content(params), do: params

  defp format_field(schema, content) do
    {Map.get(schema, "name"),
     Format.format_field(%{
       "content" => Map.get(content, Map.get(schema, "name")),
       "type" => Map.get(schema, "type"),
       "cardinality" => Map.get(schema, "cardinality"),
       "values" => Map.get(schema, "values")
     })}
  end

  @doc """
    Updates business_concept attributes
  """

  def update_business_concept(
        %BusinessConceptVersion{} = business_concept_version,
        params
      ) do
    result =
      params
      |> attrs_keys_to_atoms()
      |> confidential_changeset(business_concept_version)
      |> update_concept()

    case result do
      {:ok, _} ->
        updated_version = get_business_concept_version!(business_concept_version.id)
        refresh_cache_and_elastic(updated_version)
        {:ok, updated_version}

      _ ->
        result
    end
  end

  @doc """
  Updates a business_concept_version.

  ## Examples

      iex> update_business_concept_version(business_concept_version, %{field: new_value})
      {:ok, %BusinessConceptVersion{}}

      iex> update_business_concept_version(business_concept_version, %{field: bad_value})
      {:error, %Changeset{}}

  """
  def update_business_concept_version(
        %BusinessConceptVersion{} = business_concept_version,
        params
      ) do
    result =
      params
      |> attrs_keys_to_atoms()
      |> raise_error_if_no_content_schema()
      |> add_content_if_not_exist()
      |> merge_content_with_concept(business_concept_version)
      |> set_content_defaults()
      |> validate_concept(business_concept_version)
      |> validate_concept_content()
      |> validate_description()
      |> update_concept()

    case result do
      {:ok, _} ->
        updated_version = get_business_concept_version!(business_concept_version.id)
        refresh_cache_and_elastic(updated_version)
        {:ok, updated_version}

      _ ->
        result
    end
  end

  def bulk_update_business_concept_version(
        %BusinessConceptVersion{} = business_concept_version,
        params
      ) do
    params = attrs_keys_to_atoms(params)

    result =
      params
      |> raise_error_if_no_content_schema()
      |> add_content_if_not_exist()
      |> merge_content_with_concept(business_concept_version)
      |> update_content_schema(params, business_concept_version)
      |> bulk_validate_concept(business_concept_version)
      |> validate_concept_content(Map.get(business_concept_version, :status) != "published")
      |> validate_description()
      |> update_concept()

    case result do
      {:ok, _} ->
        updated_version = get_business_concept_version!(business_concept_version.id)
        {:ok, updated_version}

      _ ->
        result
    end
  end

  defp refresh_cache_and_elastic(%BusinessConceptVersion{} = business_concept_version) do
    business_concept_id = business_concept_version.business_concept_id
    ConceptLoader.refresh(business_concept_id)

    Publisher.publish(
      %{
        event: "concept_updated",
        resource_type: "business_concept",
        resource_id: business_concept_id
      },
      "business_concept:events"
    )
  end

  def get_concept_counts(business_concept_id) do
    case ConceptCache.get(business_concept_id, refresh: true) do
      {:ok, %{rule_count: rule_count, link_count: link_count, concept_count: concept_count}} ->
        %{rule_count: rule_count, link_count: link_count, concept_count: concept_count}

      _ ->
        %{rule_count: 0, link_count: 0, concept_count: 0}
    end
  end

  @doc """
  Returns the list of business_concept_versions.

  ## Examples

      iex> list_all_business_concept_versions(filter)
      [%BusinessConceptVersion{}, ...]

  """
  def list_all_business_concept_versions do
    BusinessConceptVersion
    |> join(:left, [v], _ in assoc(v, :business_concept))
    |> join(:left, [v, c], _ in assoc(c, :domain))
    |> preload([_, c, d], business_concept: {c, domain: d})
    |> order_by(asc: :version)
    |> Repo.all()
  end

  @doc """
  Returns the list of business_concept_versions_by_ids giving a
  list of ids

  ## Examples

      iex> business_concept_versions_by_ids([bcv_id_1, bcv_id_2], status)
      [%BusinessConceptVersion{}, ...]

  """
  def business_concept_versions_by_ids(list_business_concept_version_ids, status \\ nil) do
    BusinessConceptVersion
    |> join(:left, [v], _ in assoc(v, :business_concept))
    |> join(:left, [v, c], _ in assoc(c, :domain))
    |> preload([_, c, d], business_concept: {c, domain: d})
    |> where([v, _, _], v.id in ^list_business_concept_version_ids)
    |> include_status_in_where(status)
    |> order_by(desc: :version)
    |> Repo.all()
  end

  def list_all_business_concept_with_status(status) do
    BusinessConceptVersion
    |> join(:left, [v], _ in assoc(v, :business_concept))
    |> join(:left, [v, c], _ in assoc(c, :domain))
    |> preload([_, c, d], business_concept: {c, domain: d})
    |> include_status_in_where(status)
    |> order_by(asc: :version)
    |> Repo.all()
  end

  defp include_status_in_where(query, nil), do: query

  defp include_status_in_where(query, status) do
    query |> where([v, _], v.status in ^status)
  end

  @doc """
  Gets a single business_concept_version.

  Raises `Ecto.NoResultsError` if the Business concept version does not exist.

  ## Examples

      iex> get_business_concept_version!(123)
      %BusinessConceptVersion{}

      iex> get_business_concept_version!(456)
      ** (Ecto.NoResultsError)

  """
  def get_business_concept_version!(id) do
    BusinessConceptVersion
    |> join(:left, [v], _ in assoc(v, :business_concept))
    |> join(:left, [_, c], _ in assoc(c, :domain))
    |> join(:left, [_, _, d], _ in assoc(d, :domain_group))
    |> preload([_, c, d, g], business_concept: [domain: :domain_group])
    |> where([v, _], v.id == ^id)
    |> Repo.one!()
  end

  @doc """
  Gets a single business_concept_version by concept id and version.

  Raises `Ecto.NoResultsError` if the Business concept version does not exist.

  ## Examples

      iex> get_business_concept_version!(123, "current")
      %BusinessConceptVersion{}

      iex> get_business_concept_version!(456, 12)
      ** (Ecto.NoResultsError)

  """
  def get_business_concept_version!(id, version) do
    BusinessConceptVersion
    |> join(:left, [v], _ in assoc(v, :business_concept))
    |> join(:left, [_, c], _ in assoc(c, :domain))
    |> join(:left, [_, _, d], _ in assoc(d, :domain_group))
    |> preload([_, c, d, g], business_concept: [domain: :domain_group])
    |> where([_, c], c.id == ^id)
    |> where_version(version)
    |> Repo.one!()
  end

  def where_version(query, "current"), do: where(query, [v], v.current == true)

  def where_version(query, version), do: where(query, [v], v.id == ^version)

  @doc """
  Deletes a BusinessConceptVersion.

  ## Examples

      iex> delete_business_concept_version(data_structure)
      {:ok, %BusinessConceptVersion{}}

      iex> delete_business_concept_version(data_structure)
      {:error, %Changeset{}}

  """
  def delete_business_concept_version(
        %BusinessConceptVersion{} = business_concept_version,
        %Claims{user_id: user_id}
      ) do
    business_concept = business_concept_version.business_concept
    business_concept_id = business_concept.id

    if business_concept_version.version == 1 do
      Multi.new()
      |> Multi.delete(:business_concept_version, business_concept_version)
      |> Multi.delete(:business_concept, business_concept)
      |> Multi.run(:audit, Audit, :business_concept_deleted, [user_id])
      |> Repo.transaction()
      |> case do
        {:ok,
         %{
           business_concept: %BusinessConcept{},
           business_concept_version: %BusinessConceptVersion{} = version
         }} ->
          Publisher.publish(
            %{
              event: "concept_deleted",
              resource_type: "business_concept",
              resource_id: business_concept_id
            },
            "business_concept:events"
          )

          ConceptCache.delete(business_concept_id)
          # TODO: TD-1618 delete_search should be performed by a consumer of the event stream
          Indexer.delete(business_concept_version)
          {:ok, version}
      end
    else
      Multi.new()
      |> Multi.delete(:business_concept_version, business_concept_version)
      |> Multi.run(:audit, Audit, :business_concept_deleted, [user_id])
      |> Repo.transaction()
      |> case do
        {:ok,
         %{
           business_concept_version: %BusinessConceptVersion{} = deleted_version
         }} ->
          Indexer.delete(deleted_version)
          {:ok, get_last_version_by_business_concept_id!(business_concept_id)}
      end
    end
  end

  defp map_keys_to_atoms(key_values) do
    Map.new(key_values, fn
      {key, value} when is_binary(key) -> {String.to_existing_atom(key), value}
      {key, value} when is_atom(key) -> {key, value}
    end)
  end

  def attrs_keys_to_atoms(key_values) do
    map = map_keys_to_atoms(key_values)

    case map.business_concept do
      %BusinessConcept{} -> map
      %{} = concept -> Map.put(map, :business_concept, map_keys_to_atoms(concept))
      _ -> map
    end
  end

  defp raise_error_if_no_content_schema(params) do
    if not Map.has_key?(params, :content_schema) do
      raise "Content Schema is not defined for Business Concept"
    end

    params
  end

  defp add_content_if_not_exist(params) do
    if Map.has_key?(params, :content) do
      params
    else
      Map.put(params, :content, %{})
    end
  end

  def validate_new_concept(params) do
    changeset = BusinessConceptVersion.create_changeset(%BusinessConceptVersion{}, params)
    Map.put(params, :changeset, changeset)
  end

  defp validate_concept(params, %BusinessConceptVersion{} = business_concept_version) do
    changeset = BusinessConceptVersion.update_changeset(business_concept_version, params)
    Map.put(params, :changeset, changeset)
  end

  defp bulk_validate_concept(params, %BusinessConceptVersion{} = business_concept_version) do
    changeset = BusinessConceptVersion.bulk_update_changeset(business_concept_version, params)
    Map.put(params, :changeset, changeset)
  end

  defp confidential_changeset(params, %BusinessConceptVersion{} = business_concept_version) do
    changeset = BusinessConceptVersion.confidential_changeset(business_concept_version, params)
    Map.put(params, :changeset, changeset)
  end

  defp merge_content_with_concept(params, %BusinessConceptVersion{} = business_concept_version) do
    content = Map.get(params, :content)
    concept_content = Map.get(business_concept_version, :content, %{})
    new_content = Map.merge(concept_content, content)
    Map.put(params, :content, new_content)
  end

  defp set_content_defaults(params) do
    content = Map.get(params, :content)
    content_schema = Map.get(params, :content_schema)

    case content do
      nil ->
        params

      _ ->
        content = Format.apply_template(content, content_schema)
        Map.put(params, :content, content)
    end
  end

  defp validate_concept_content(params, in_progress \\ nil)

  defp validate_concept_content(params, in_progress) do
    changeset = Map.get(params, :changeset)

    if changeset.valid? do
      do_validate_concept_content(params, in_progress)
    else
      params
    end
  end

  defp do_validate_concept_content(params, in_progress) do
    content = Map.get(params, :content)
    content_schema = Map.get(params, :content_schema)
    changeset = Validation.build_changeset(content, content_schema)

    case in_progress do
      false -> validate_content(changeset, params)
      _ -> put_in_progress(changeset, params)
    end
  end

  defp validate_description(params) do
    if Map.has_key?(params, :description) && Map.has_key?(params, :in_progress) &&
         !params.in_progress do
      do_validate_description(params)
    else
      params
    end
  end

  defp do_validate_description(params) do
    import Ecto.Changeset, only: [put_change: 3]

    if !params.description == %{} do
      params
      |> Map.put(:changeset, put_change(params.changeset, :in_progress, true))
      |> Map.put(:in_progress, true)
    else
      params
      |> Map.put(:changeset, put_change(params.changeset, :in_progress, false))
      |> Map.put(:in_progress, false)
    end
  end

  defp put_in_progress(changeset, params) do
    import Ecto.Changeset, only: [put_change: 3]

    if changeset.valid? do
      params
      |> Map.put(:changeset, put_change(params.changeset, :in_progress, false))
      |> Map.put(:in_progress, false)
    else
      params
      |> Map.put(:changeset, put_change(params.changeset, :in_progress, true))
      |> Map.put(:in_progress, true)
    end
  end

  defp update_content_schema(changes, _params, %BusinessConceptVersion{status: "draft"}),
    do: changes

  defp update_content_schema(changes, params, _bcv) do
    updated =
      params
      |> Map.get(:content)
      |> Map.keys()

    schema =
      changes
      |> Map.get(:content_schema)
      |> Enum.filter(&(Map.get(&1, "name") in updated))

    Map.put(changes, :content_schema, schema)
  end

  defp update_concept(%{changeset: changeset}) do
    Multi.new()
    |> Multi.update(:updated, changeset)
    |> Multi.run(:audit, Audit, :business_concept_updated, [changeset])
    |> Repo.transaction()
  end

  defp validate_content(changeset, params) do
    case changeset.valid? do
      false -> Map.put(params, :changeset, changeset)
      _ -> params
    end
  end

  defp insert_concept(%{changeset: changeset}) do
    Multi.new()
    |> Multi.insert(:business_concept_version, changeset)
    |> Multi.run(:audit, Audit, :business_concept_created, [])
    |> Repo.transaction()
  end

  def get_business_concept_by_name(name) do
    BusinessConceptVersion
    |> join(:left, [v], _ in assoc(v, :business_concept))
    |> join(:left, [v, c], _ in assoc(c, :domain))
    |> where([v], ilike(v.name, ^"%#{name}%"))
    |> preload([_, c, d], business_concept: {c, domain: d})
    |> order_by(asc: :version)
    |> Repo.all()
  end

  def get_business_concept_by_term(term) do
    BusinessConceptVersion
    |> join(:left, [v], _ in assoc(v, :business_concept))
    |> join(:left, [v, c], _ in assoc(c, :domain))
    |> where([v], ilike(v.name, ^"%#{term}%") or ilike(v.description, ^"%#{term}%"))
    |> preload([_, c, d], business_concept: {c, domain: d})
    |> order_by(asc: :version)
    |> Repo.all()
  end

  def get_template(%BusinessConceptVersion{business_concept: business_concept}) do
    get_template(business_concept)
  end

  def get_template(%BusinessConcept{type: type}) do
    TemplateCache.get_by_name!(type)
  end

  def get_content_schema(%BusinessConceptVersion{business_concept: business_concept}) do
    get_content_schema(business_concept)
  end

  def get_content_schema(%BusinessConcept{type: type}) do
    Templates.content_schema(type)
  end

  def get_completeness(%BusinessConceptVersion{content: content} = bcv) do
    case get_template(bcv) do
      template -> Templates.completeness(content, template)
    end
  end

  def add_parents(%BusinessConceptVersion{business_concept: %{domain_id: domain_id}} = bcv) do
    Map.put(bcv, :domain_parents, TdBg.Taxonomies.get_parents(domain_id))
  end

  @doc """
  Returns count of business concepts applying clauses dynamically
  """
  def count(clauses) do
    clauses
    |> Enum.reduce(BusinessConcept, fn
      {:domain_id, domain_id}, q ->
        where(q, [d], d.domain_id == ^domain_id)

      {:deprecated, false}, q ->
        q
        |> join(:inner, [c], bcv in assoc(c, :versions))
        |> where([c, bcv], bcv.current == true and bcv.status != "deprecated")
    end)
    |> select([_], count())
    |> Repo.one!()
  end
end
