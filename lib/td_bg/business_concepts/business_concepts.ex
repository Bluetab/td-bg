defmodule TdBg.BusinessConcepts do
  @moduledoc """
  The BusinessConcepts context.
  """

  import Ecto.Query

  alias Ecto.Changeset
  alias Ecto.Multi
  alias TdBg.Auth.Claims
  alias TdBg.BusinessConcepts.Audit
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.BusinessConcepts.BusinessConceptVersions.RecordEmbedding
  alias TdBg.BusinessConcepts.Links
  alias TdBg.BusinessConcepts.RecordEmbeddings
  alias TdBg.Cache.ConceptLoader
  alias TdBg.I18nContents.I18nContent
  alias TdBg.I18nContents.I18nContents
  alias TdBg.Repo
  alias TdBg.Search.Indexer
  alias TdBg.Taxonomies
  alias TdCache.ConceptCache
  alias TdCache.EventStream.Publisher
  alias TdCache.I18nCache
  alias TdCache.TemplateCache
  alias TdCluster.Cluster.TdAi.Embeddings
  alias TdCluster.Cluster.TdAi.Indices
  alias TdDfLib.Format
  alias TdDfLib.Templates
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
  Fetch an exsisting business_concept by its id
  """
  def get_business_concept(business_concept_id) do
    BusinessConcept
    |> where([c], c.id == ^business_concept_id)
    |> preload([:shared_to, :domain])
    |> Repo.one()
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

  def get_all_versions_by_business_concept_ids(_business_concept_ids, _opts \\ [])

  def get_all_versions_by_business_concept_ids([], _opts), do: []

  def get_all_versions_by_business_concept_ids(business_concept_ids, opts) do
    preloads = Keyword.get(opts, :preload, business_concept: [:shared_to])

    BusinessConceptVersion
    |> where([v], v.business_concept_id in ^business_concept_ids)
    |> preload(^preloads)
    |> Repo.all()
  end

  def get_active_ids do
    BusinessConceptVersion
    |> where([v], v.current == true)
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
    |> valid_creation_changeset(opts)
    |> insert_concept()
    |> index_on_success(opts[:index])
  end

  def new_concept_validations(params, opts \\ []) do
    business_concept_version =
      Keyword.get(opts, :business_concept_version, %BusinessConceptVersion{})

    params
    |> validate_new_concept(business_concept_version)
    |> validate_concept_content(opts[:in_progress])
  end

  defp valid_creation_changeset(params, opts) do
    params
    |> Map.put_new(:lang, get_default_lang())
    |> attrs_keys_to_atoms()
    |> raise_error_if_no_content_schema()
    |> maybe_domain_ids()
    |> new_concept_validations(opts)
  end

  defp index_on_success({:ok, %{} = res}, true) do
    with %{business_concept_version: %{id: id}} <- res do
      %{business_concept_id: business_concept_id} = bcv = get_business_concept_version!(id)
      ConceptLoader.refresh(business_concept_id)
      {:ok, bcv}
    end
  end

  defp index_on_success(result, _), do: result

  defp maybe_domain_ids(%{domain_id: domain_id} = params),
    do: Map.put(params, :domain_ids, [domain_id])

  defp maybe_domain_ids(%{business_concept: %{domain_id: domain_id}} = params),
    do: Map.put(params, :domain_ids, [domain_id])

  defp maybe_domain_ids(params), do: Map.put(params, :domain_ids, nil)

  @doc """
    Updates business_concept attributes
  """

  def update_business_concept(%BusinessConceptVersion{} = business_concept_version, params) do
    result =
      params
      |> attrs_keys_to_atoms()
      |> confidential_changeset(business_concept_version)
      |> update_concept(:business_concept_updated)

    case result do
      {:ok, _} ->
        updated_version = get_business_concept_version!(business_concept_version.id)

        refresh_cache_and_elastic(updated_version)
        {:ok, updated_version}

      _ ->
        result
    end
  end

  def update_concept_validations(params, business_concept_version, opts \\ []) do
    in_progress = Keyword.get(opts, :in_progress, business_concept_version.status == "draft")

    params
    |> validate_concept(business_concept_version)
    |> validate_concept_content(in_progress)
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
      |> update_concept_validations(business_concept_version)
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
      |> update_concept()

    case result do
      {:ok, _} ->
        updated_version = get_business_concept_version!(business_concept_version.id)
        {:ok, updated_version}

      _ ->
        result
    end
  end

  def refresh_cache_and_elastic(%BusinessConceptVersion{} = business_concept_version) do
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
      {:ok,
       %{
         rule_count: rule_count,
         link_count: link_count,
         link_tags: link_tags,
         concept_count: concept_count
       }} ->
        %{
          rule_count: rule_count,
          link_count: link_count,
          link_tags: link_tags,
          concept_count: concept_count,
          has_rules: rule_count > 0,
          has_concept_links: concept_count > 0
        }

      _ ->
        %{
          rule_count: 0,
          link_count: 0,
          concept_count: 0,
          has_rules: false,
          has_concept_links: false
        }
    end
    |> maybe_update_link_tags()
  end

  defp maybe_update_link_tags(%{link_count: 0} = map) do
    Map.put(map, :link_tags, ["_none"])
  end

  defp maybe_update_link_tags(%{link_count: n} = map) when n > 0 do
    Map.update(map, :link_tags, ["_tagless"], fn
      [] -> ["_tagless"]
      tags -> tags
    end)
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
    |> preload([_, c, d], business_concept: [:domain, :shared_to])
    |> order_by(asc: :version)
    |> Repo.all()
  end

  def list_business_concept_versions(criteria \\ []) do
    base_query = join(BusinessConceptVersion, :left, [v], _ in assoc(v, :business_concept))

    criteria
    |> Enum.reduce(base_query, fn
      :published, query -> where(query, [v, _], v.status == "published")
      {:type, type}, query -> where(query, [_, c], c.type == ^type)
    end)
    |> preload([_, _], :business_concept)
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
    |> preload([_, c, d, g], business_concept: [{:domain, :domain_group}, :shared_to])
    |> where([v, _], v.id == ^id)
    |> Repo.one!()
  end

  @doc """
  Gets a single business_concept_version by concept id and version.

  ## Examples

      iex> get_business_concept_version(123, "current")
      %BusinessConceptVersion{}

      iex> get_business_concept_version(456, 12)
      ** nil

  """
  def get_business_concept_version(id, version, opts \\ []) do
    preload =
      Keyword.get(opts, :preload, business_concept: [{:domain, :domain_group}, :shared_to])

    BusinessConceptVersion
    |> join(:left, [v], _ in assoc(v, :business_concept))
    |> join(:left, [_, c], _ in assoc(c, :domain))
    |> join(:left, [_, _, d], _ in assoc(d, :domain_group))
    |> preload([_, c, d, g], ^preload)
    |> where([_, c], c.id == ^id)
    |> where_version(version)
    |> Repo.one()
  end

  defp where_version(query, "latest"),
    do:
      query
      |> order_by(desc: :version)
      |> limit(1)

  defp where_version(query, "current"), do: where(query, [v], v.current == true)

  defp where_version(query, version), do: where(query, [v], v.id == ^version)

  @doc """
  Deletes a BusinessConceptVersion.

  ## Examples

      iex> delete_business_concept_version(data_structure)
      {:ok, %BusinessConceptVersion{}}

      iex> delete_business_concept_version(data_structure)
      {:error, %Changeset{}}

  """
  def delete_business_concept_version(
        %BusinessConceptVersion{id: bcvid} = business_concept_version,
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
          Indexer.delete([bcvid])

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
           business_concept_version: %BusinessConceptVersion{id: bcv_id}
         }} ->
          Indexer.delete([bcv_id])
          {:ok, get_last_version_by_business_concept_id!(business_concept_id)}
      end
    end
  end

  defp map_keys_to_atoms(key_values) do
    Map.new(key_values, fn
      {key, value} when is_binary(key) -> {String.to_atom(key), value}
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
    Map.put_new(params, :content, %{})
  end

  def validate_new_concept(params, old_business_concept_version \\ %BusinessConceptVersion{}) do
    changeset =
      BusinessConceptVersion.create_changeset(
        %BusinessConceptVersion{},
        params,
        old_business_concept_version
      )

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

  def merge_content_with_concept(params, %BusinessConceptVersion{} = business_concept_version) do
    content = Map.get(params, :content)
    concept_content = Map.get(business_concept_version, :content, %{})
    Map.put(params, :content, Map.merge(concept_content, content))
  end

  def merge_i18n_content_with_concept(params, %BusinessConceptVersion{id: id}) do
    i18n_content = Map.get(params, :i18n_content)

    concept_i18n_content =
      Map.new(I18nContents.get_all_i18n_content_by_bcv_id(id) || [], &{&1.lang, &1})

    updated_i18n_content =
      Map.new(i18n_content, fn {lang, content} ->
        existing_lang_content = Map.get(concept_i18n_content, lang, %{})
        exsiting_name = Map.get(existing_lang_content, :name)
        exsiting_content = Map.get(existing_lang_content, :content, %{})

        updated_content =
          content
          |> Map.put_new("name", exsiting_name)
          |> Map.update("content", %{}, &Map.merge(exsiting_content, &1))

        {lang, updated_content}
      end)

    Map.put(params, :i18n_content, updated_i18n_content)
  end

  defp validate_concept_content(
         %{changeset: %{valid?: true} = changeset, i18n_content: i18n_content} = params,
         in_progress
       ) do
    # content might be updated at this point from BusinessConceptVersion.create_changeset/2
    bc_content = Changeset.get_field(changeset, :content, params.content)
    default_lang = get_default_lang()
    required_langs = get_required_langs()
    content_schema = Map.get(params, :content_schema)

    updated_changeset =
      i18n_content
      |> merge_content_with_i18n_content(bc_content, content_schema)
      |> Map.put(default_lang, %{"content" => bc_content})
      |> Enum.map(fn {lang, %{"content" => content}} ->
        if lang in required_langs || lang == default_lang do
          changeset =
            changeset
            |> Changeset.put_change(:in_progress, false)
            |> Changeset.force_change(:content, content)
            |> BusinessConceptVersion.validate_content()

          {lang, changeset}
        else
          {lang, nil}
        end
      end)
      |> Enum.reject(fn {_lang, content} -> is_nil(content) end)
      |> maybe_put_in_progress(changeset, in_progress)

    %{params | changeset: updated_changeset}
  end

  defp validate_concept_content(%{changeset: %{valid?: true} = changeset} = params, in_progress) do
    updated_changeset =
      changeset
      |> Changeset.put_change(:in_progress, false)
      |> force_content_change(params)
      |> BusinessConceptVersion.validate_content()
      |> maybe_put_in_progress(changeset, in_progress)

    %{params | changeset: updated_changeset}
  end

  defp validate_concept_content(%{} = params, _in_progress), do: params

  defp force_content_change(changeset, %{content: %{} = content}) do
    concept_content = changeset |> Changeset.get_field(:content, content) |> Map.merge(content)
    Changeset.force_change(changeset, :content, concept_content)
  end

  defp force_content_change(changeset, _params), do: changeset

  defp maybe_put_in_progress([_ | _] = i18_changesets, _source_changeset, false) do
    invalid = Enum.find(i18_changesets, fn {_lang, %{valid?: valid}} -> !valid end)

    case invalid do
      nil ->
        find_default_i18n_changeset(i18_changesets)

      {_locale, changeset = %Changeset{}} ->
        changeset
    end
  end

  defp maybe_put_in_progress(
         [_ | _] = i18_changesets,
         changeset,
         _in_progress
       ) do
    i18_changesets
    |> Enum.filter(fn {_lang, %{valid?: valid}} -> !valid end)
    |> then(fn
      [] ->
        find_default_i18n_changeset(i18_changesets)

      [_ | _] = invalid_changesets ->
        invalid_changeset =
          Enum.find(invalid_changesets, fn {_lang, changeset} ->
            not Enum.empty?(reject_content_completion_errors(changeset))
          end)

        case invalid_changeset do
          {_lang, %Changeset{} = invalid_changeset} ->
            invalid_changeset

          nil ->
            Changeset.put_change(changeset, :in_progress, true)
        end
    end)
  end

  defp maybe_put_in_progress(changeset_with_content_validation, _source_changeset, false),
    do: changeset_with_content_validation

  defp maybe_put_in_progress(
         %{valid?: true} = changeset_with_content_validation,
         _source_changeset,
         _in_progress
       ) do
    changeset_with_content_validation
  end

  defp maybe_put_in_progress(
         %{errors: [_ | _]} = changeset_with_content_validation,
         changeset,
         _in_progress
       ) do
    if Enum.empty?(reject_content_completion_errors(changeset_with_content_validation)) do
      Changeset.put_change(changeset, :in_progress, true)
    else
      changeset_with_content_validation
    end
  end

  defp find_default_i18n_changeset(i18_changesets) do
    default_lang = get_default_lang()

    Enum.reduce_while(i18_changesets, %{}, fn {lang, changeset}, acc ->
      if lang == default_lang, do: {:halt, changeset}, else: {:cont, acc}
    end)
  end

  def reject_content_completion_errors(%{errors: [_ | _] = errors}) do
    {_message, content_errors} = errors[:content]

    Enum.reject(content_errors, fn
      {_field, {_message, detail}} when is_list(detail) ->
        detail_base = Keyword.take(detail, [:validation, :kind, :type, :count])

        detail_base[:validation] == :required or
          Keyword.equal?(detail_base,
            validation: :length,
            kind: :min,
            type: :list,
            count: 1
          )

      _other ->
        false
    end)
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

  def update_concept(
        %{changeset: changeset} = params,
        concept_or_version \\ :business_concept_version_updated
      ) do
    Multi.new()
    |> Multi.update(:updated, changeset)
    |> maybe_upsert_i18n_content(params)
    |> Multi.run(:audit, Audit, concept_or_version, [changeset])
    |> Repo.transaction()
  end

  def insert_concept(%{changeset: changeset} = params) do
    Multi.new()
    |> Multi.insert(:business_concept_version, changeset)
    |> maybe_upsert_i18n_content(params)
    |> Multi.run(:audit, Audit, :business_concept_created, [])
    |> Repo.transaction()
  end

  def version_concept(%{changeset: changeset} = params, opts \\ []) do
    Multi.new()
    |> Multi.insert(:current, Changeset.change(changeset, current: false))
    |> i18_action_on_version_concept(params, opts)
    |> Multi.run(:audit, Audit, :business_concept_versioned, [])
    |> Repo.transaction()
  end

  defp i18_action_on_version_concept(multi, params, opts) do
    case Keyword.get(opts, :trigger, :single) do
      :single -> maybe_i18n_content_new_version(multi, params)
      :bulk -> maybe_upsert_i18n_content(multi, params)
    end
  end

  def publish_version_concept(
        %{
          changeset: changeset,
          params: %{"business_concept" => %{"id" => business_concept_id}},
          action: action
        } = params
      ) do
    query =
      from(
        c in BusinessConceptVersion,
        where: c.business_concept_id == ^business_concept_id and c.status == "published"
      )

    multi_upsert = if action === :create, do: &Multi.insert/3, else: &Multi.update/3

    Multi.new()
    |> Multi.update_all(:versioned, query, set: [status: "versioned", current: false])
    |> multi_upsert.(:published, Changeset.change(changeset, current: true))
    |> maybe_upsert_i18n_content(params)
    |> Multi.run(:audit_published, Audit, :business_concept_published, [])
    |> Repo.transaction()
  end

  def get_concept_by_name_in_domain(name, domain_id) do
    BusinessConcept
    |> join(:inner, [c], v in assoc(c, :versions))
    |> join(:left, [c, v], d in assoc(c, :domain))
    |> where([c, v], v.name == ^to_string(name) and c.domain_id == ^domain_id)
    |> preload([c, _v, d],
      domain: d,
      shared_to: [],
      versions: ^from(v in BusinessConceptVersion, order_by: [desc: v.version])
    )
    |> Repo.one()
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

  def get_completeness(bcv, content) do
    case get_template(bcv) do
      nil -> nil
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

  def share(%BusinessConcept{} = concept, domain_ids) do
    domains = Taxonomies.list_domains(%{domain_ids: domain_ids})

    changeset =
      concept
      |> Repo.preload(:shared_to)
      |> BusinessConcept.changeset(%{shared_to: domains})

    Multi.new()
    |> Multi.update(:updated, changeset)
    |> Multi.run(:audit, Audit, :business_concept_updated, [changeset])
    |> Repo.transaction()
    |> on_share()
  end

  def get_domain_ids(%{domain_id: domain_id, shared_to: shared_to}) do
    shared_ids = Enum.map(shared_to, & &1.id)
    Enum.uniq([domain_id | shared_ids])
  end

  def get_domain_ids(%{domain_ids: domain_ids}), do: domain_ids

  def get_domain_ids(%{"domain_ids" => domain_ids}), do: domain_ids

  def get_domain_ids(_), do: []

  def get_last_change(%BusinessConceptVersion{
        last_change_at: bcv_at,
        last_change_by: bcv_by,
        business_concept: %{last_change_at: bc_at, last_change_by: bc_by}
      }) do
    case DateTime.compare(bcv_at, bc_at) do
      :gt -> {bcv_at, bcv_by}
      _ -> {bc_at, bc_by}
    end
  end

  def get_last_change_version(%BusinessConceptVersion{
        last_change_at: last_change_at,
        last_change_by: last_change_by
      }),
      do: {last_change_at, last_change_by}

  def get_default_lang do
    {:ok, lang} = I18nCache.get_default_locale()
    lang
  end

  defp get_required_langs do
    {:ok, required_langs} = I18nCache.get_required_locales()
    required_langs
  end

  def embeddings([]), do: {:ok, []}

  def embeddings(business_concept_versions) do
    business_concept_versions
    |> Enum.map(&embedding_attributes/1)
    |> Embeddings.all()
  end

  def generate_vector(_version_or_params, collection_name \\ nil)

  def generate_vector(
        %BusinessConceptVersion{record_embeddings: [%RecordEmbedding{} = record]},
        _collection_name
      ) do
    {record.collection, record.embedding}
  end

  def generate_vector(%BusinessConceptVersion{} = version, collection_name) do
    version
    |> embedding_attributes()
    |> Embeddings.generate_vector(collection_name)
    |> tap(fn {:ok, _vector} ->
      RecordEmbeddings.upsert_from_concepts_async(version.business_concept_id)
    end)
    |> then(fn {:ok, vector} -> vector end)
  end

  def generate_vector(%{id: id, version: version}, collection_name) do
    collection_name = collection_name_or_default(collection_name)

    preload = [
      record_embeddings: where(RecordEmbedding, [re], re.collection == ^collection_name),
      business_concept: [{:domain, :domain_group}, :shared_to]
    ]

    id
    |> get_business_concept_version(version, preload: preload)
    |> generate_vector(collection_name)
  end

  def generate_vector(nil, _collection_name), do: nil

  def versions_with_outdated_embeddings(collections, opts \\ []) do
    base =
      Enum.reduce(opts, BusinessConceptVersion, fn
        {:limit, limit}, q -> limit(q, ^limit)
        _, q -> q
      end)

    outdated =
      base
      |> join(:left, [bcv, re], re in assoc(bcv, :record_embeddings))
      |> where([bcv, re], is_nil(re.updated_at) or re.updated_at < bcv.updated_at)
      |> select([bcv], bcv.business_concept_id)

    join_collections_set =
      from(cs in fragment("SELECT unnest(?::text[]) AS collection", ^collections),
        select: %{collection: cs.collection}
      )

    missing =
      base
      |> join(:cross, [bcv, cs], cs in subquery(join_collections_set))
      |> join(:left, [bcv, cs, re], re in RecordEmbedding,
        on: re.business_concept_version_id == bcv.id and cs.collection == re.collection
      )
      |> where([bcv, cs, re], is_nil(re.id))
      |> select([bcv], bcv.business_concept_id)

    missing
    |> union_all(^outdated)
    |> distinct(true)
    |> Repo.all()
  end

  defp collection_name_or_default(collection_name) when is_binary(collection_name),
    do: collection_name

  defp collection_name_or_default(nil) do
    {:ok, %{collection_name: collection_name}} = Indices.first_enabled()
    collection_name
  end

  defp embedding_attributes(%BusinessConceptVersion{
         name: name,
         content: content,
         business_concept: business_concept
       }) do
    "#{name} #{business_concept.type} #{business_concept.domain.external_id}"
    |> add_descriptions(content, business_concept)
    |> add_links_to_vector(business_concept.id)
    |> String.trim()
  end

  defp add_descriptions(text, content, business_concept) do
    case get_template(business_concept) do
      nil ->
        text

      %{content: template_content} = template ->
        description_fields =
          template_content
          |> Format.flatten_content_fields()
          |> Enum.filter(&(&1["widget"] in ["enriched_text", "textarea"]))
          |> Enum.map(& &1["name"])

        descriptions =
          content
          |> Format.search_values(template, domain_id: business_concept.domain.id)
          |> Map.take(description_fields)
          |> Enum.map_join(" ", fn
            {_field, %{"value" => value}} -> value
            _other -> ""
          end)

        text <> " " <> descriptions
    end
  end

  defp add_links_to_vector(text, business_concept_id) do
    links_text =
      business_concept_id
      |> Links.get_rand_links("business_concept", "data_structure")
      |> Enum.map_join(" ", &link_embedding/1)

    text <> " " <> links_text
  end

  defp link_embedding(link) do
    "#{Map.get(link, :name)} #{Map.get(link, :type)} #{Map.get(link, :description)}"
  end

  defp on_share({:ok, %{updated: %{id: id, shared_to: shared_to} = updated} = reply}) do
    ConceptLoader.refresh(id)
    {:ok, %{reply | updated: %{updated | shared_to: TdBg.Taxonomies.add_parents(shared_to)}}}
  end

  defp on_share(error), do: error

  defp maybe_upsert_i18n_content(multi, %{i18n_content: i18n_content} = _params) do
    Multi.run(multi, :i18n_content, fn _, map ->
      bcv = get_bcv_from_multimap(map)

      i18n_content_entries =
        Enum.reduce(i18n_content, [], fn {lang, content}, acc ->
          [validate_i18n_content(bcv, content, lang) | acc]
        end)

      if Enum.any?(i18n_content_entries, &(&1 == :error)) do
        {:error, :insert_i18n_content}
      else
        result =
          Repo.insert_all(I18nContent, i18n_content_entries,
            conflict_target: [:business_concept_version_id, :lang],
            on_conflict: {:replace, [:name, :content, :updated_at]},
            returning: [:id, :name, :lang, :business_concept_version_id, :content]
          )

        {:ok, result}
      end
    end)
  end

  defp maybe_upsert_i18n_content(multi, _params), do: multi

  defp validate_i18n_content(%{id: bcv_id}, content, lang) do
    changeset =
      content
      |> Map.put("lang", lang)
      |> Map.put("business_concept_version_id", bcv_id)
      |> I18nContent.changeset()

    if changeset.valid? do
      ts = DateTime.utc_now()

      changeset
      |> Map.get(:changes)
      |> Map.put(:inserted_at, ts)
      |> Map.put(:updated_at, ts)
    else
      :error
    end
  end

  defp maybe_i18n_content_new_version(multi, %{
         business_concept_version: %BusinessConceptVersion{id: old_bcv_id}
       }) do
    maybe_i18n_content_new_version(multi, old_bcv_id)
  end

  defp maybe_i18n_content_new_version(multi, %{id: old_bcv_id}) do
    maybe_i18n_content_new_version(multi, old_bcv_id)
  end

  defp maybe_i18n_content_new_version(multi, old_bcv_id) do
    case I18nContents.get_all_i18n_content_by_bcv_id(old_bcv_id) do
      [] ->
        multi

      i18n_bc_contents ->
        Multi.run(multi, :i18n_content, fn _, %{current: %{id: current_bcv_id}} ->
          i18n_content_entries = get_i18n_bc_entries(i18n_bc_contents, current_bcv_id)

          result =
            Repo.insert_all(I18nContent, i18n_content_entries,
              returning: [:id, :name, :lang, :business_concept_version_id, :content]
            )

          {:ok, result}
        end)
    end
  end

  defp get_i18n_bc_entries(i18n_bc_contents, current_bcv_id) do
    Enum.map(i18n_bc_contents, fn record ->
      ts = DateTime.utc_now()

      record
      |> Map.from_struct()
      |> Map.drop([:id, :__meta__, :business_concept_version])
      |> Map.put(:business_concept_version_id, current_bcv_id)
      |> Map.put(:inserted_at, ts)
      |> Map.put(:updated_at, ts)
    end)
  end

  defp get_bcv_from_multimap(%{updated: bcv}), do: bcv
  defp get_bcv_from_multimap(%{business_concept_version: bcv}), do: bcv
  defp get_bcv_from_multimap(%{current: bcv}), do: bcv
  defp get_bcv_from_multimap(%{published: bcv}), do: bcv

  defp merge_content_with_i18n_content(i18n_content, bc_content, content_schema) do
    not_string_template_keys =
      content_schema
      |> Enum.filter(fn
        %{"widget" => widget} ->
          widget not in ["enriched_text", "string"]

        _ ->
          false
      end)
      |> Enum.map(& &1["name"])

    not_string_values = Map.take(bc_content, not_string_template_keys)

    Enum.reduce(i18n_content, %{}, fn {lang, %{"content" => content} = data}, acc ->
      new_content = Map.merge(not_string_values, content)
      new_data = Map.put(data, "content", new_content)
      Map.put(acc, lang, new_data)
    end)
  end
end
