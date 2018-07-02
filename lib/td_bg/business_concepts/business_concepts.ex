defmodule TdBg.BusinessConcepts do
  @moduledoc """
  The BusinessConcepts context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Changeset
  alias Ecto.Multi
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Repo
  alias ValidationError

  @search_service Application.get_env(:td_bg, :elasticsearch)[:search_service]

  @changeset :changeset
  @content :content
  @content_schema :content_schema

  @string "string"
  @list "list"
  @variable_list "variable_list"

  @doc """
    check business concept name availability
  """
  def check_business_concept_name_availability(type, name, exclude_concept_id \\ nil)

  def check_business_concept_name_availability(type, name, _exclude_concept_id)
      when is_nil(name) or is_nil(type),
      do: {:name_available}

  def check_business_concept_name_availability(type, name, exclude_concept_id) do
    status = [BusinessConcept.status().versioned, BusinessConcept.status().deprecated]

    count =
      BusinessConcept
      |> join(:left, [c], _ in assoc(c, :aliases))
      |> join(:left, [c, a], _ in assoc(c, :versions))
      |> where([c, a, v], c.type == ^type and v.status not in ^status)
      |> include_name_where(name, exclude_concept_id)
      |> select([c, a, v], count(c.id))
      |> Repo.one!()

    if count == 0, do: {:name_available}, else: {:name_not_available}
  end

  defp include_name_where(query, name, nil) do
    query |> where([_, a, v], v.name == ^name or a.name == ^name)
  end

  defp include_name_where(query, name, exclude_concept_id) do
    query
    |> where(
      [c, a, v],
      (c.id != ^exclude_concept_id and (v.name == ^name or a.name == ^name)) or
        (c.id == ^exclude_concept_id and a.name == ^name)
    )
  end

  @doc """
    count published business concepts
    business concept must be of indicated type
    business concept are resticted to indicated id list
  """
  def count_published_business_concepts(type, ids) do
    published = BusinessConcept.status().published

    BusinessConcept
    |> join(:left, [c], _ in assoc(c, :versions))
    |> where([c, v], c.type == ^type and c.id in ^ids and v.status == ^published)
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

  @doc """
  Gets a single business_concept.

  Raises `Ecto.NoResultsError` if the Business concept does not exist.

  ## Examples

      iex> get_current_version_by_business_concept_id!(123)
      %BusinessConcept{}

      iex> get_current_version_by_business_concept_id!(456)
      ** (Ecto.NoResultsError)

  """
  def get_current_version_by_business_concept_id!(business_concept_id) do
    BusinessConceptVersion
    |> where([v], v.business_concept_id == ^business_concept_id)
    |> order_by(desc: :version)
    |> limit(1)
    |> preload(business_concept: [:aliases, :domain])
    |> Repo.one!()
  end

  def get_current_version_by_business_concept_id!(business_concept_id, %{current: current}) do
    BusinessConceptVersion
    |> where([v], v.business_concept_id == ^business_concept_id)
    |> where([v], v.current == ^current)
    |> order_by(desc: :version)
    |> limit(1)
    |> preload(business_concept: [:aliases, :domain])
    |> Repo.one!()
  end

  @doc """
  Creates a business_concept.

  ## Examples

      iex> create_business_concept(%{field: value})
      {:ok, %BusinessConceptVersion{}}

      iex> create_business_concept(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_business_concept(attrs \\ %{}) do
    result =
      attrs
      |> attrs_keys_to_atoms
      |> raise_error_if_no_content_schema
      |> set_content_defaults
      |> validate_new_concept
      |> validate_concept_content
      |> insert_concept

    case result do
      {:ok, business_concept_version} ->
        new_version = get_business_concept_version!(business_concept_version.id)
        business_concept_id = new_version.business_concept_id
        params = retrieve_last_bc_version_params(business_concept_id)
        index_business_concept_versions(business_concept_id, params)
        {:ok, new_version}

      _ ->
        result
    end
  end

  @doc """
  Creates a new business_concept version.

  """
  def version_business_concept(user, %BusinessConceptVersion{} = business_concept_version) do
    business_concept = business_concept_version.business_concept
    business_concept =
      business_concept
      |> Map.put("last_change_by", user.id)
      |> Map.put("last_change_at", DateTime.utc_now())

    draft_attrs = Map.from_struct(business_concept_version)

    draft_attrs =
      draft_attrs
      |> Map.put("business_concept", business_concept)
      |> Map.put("last_change_by", user.id)
      |> Map.put("last_change_at", DateTime.utc_now())
      |> Map.put("status", BusinessConcept.status().draft)
      |> Map.put("version", business_concept_version.version + 1)

    result =
      draft_attrs
      |> attrs_keys_to_atoms
      |> validate_new_concept
      |> version_concept(business_concept_version)

    case result do
      {:ok, %{current: new_version}} ->
        business_concept_id = new_version.business_concept_id
        params = retrieve_last_bc_version_params(business_concept_id)
        index_business_concept_versions(business_concept_id, params)
        result

      _ ->
        result
    end
  end

  @doc """
  Updates a business_concept.

  ## Examples

      iex> update_business_concept_version(business_concept_version, %{field: new_value})
      {:ok, %BusinessConceptVersion{}}

      iex> update_business_concept_version(business_concept_version, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_business_concept_version(%BusinessConceptVersion{} = business_concept_version, attrs) do
    result =
      attrs
      |> attrs_keys_to_atoms
      |> raise_error_if_no_content_schema
      |> add_content_if_not_exist
      |> merge_content_with_concept(business_concept_version)
      |> set_content_defaults
      |> validate_concept(business_concept_version)
      |> validate_concept_content
      |> update_concept

    case result do
      {:ok, _} ->
        updated_version = get_business_concept_version!(business_concept_version.id)
        business_concept_id = updated_version.business_concept_id
        params = retrieve_last_bc_version_params(business_concept_id)
        index_business_concept_versions(business_concept_id, params)
        {:ok, updated_version}

      _ ->
        result
    end
  end

  def update_business_concept_version_status(
        %BusinessConceptVersion{} = business_concept_version,
        attrs
      ) do
    result =
      business_concept_version
      |> BusinessConceptVersion.update_status_changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated_version} ->
        business_concept_id = updated_version.business_concept_id
        params = retrieve_last_bc_version_params(business_concept_id)
        index_business_concept_versions(business_concept_id, params)
        result

      _ ->
        result
    end
  end

  def publish_business_concept_version(business_concept_version) do
    status_published = BusinessConcept.status().published
    attrs = %{status: status_published}

    business_concept_id = business_concept_version.business_concept.id

    query =
      from(
        c in BusinessConceptVersion,
        where: c.business_concept_id == ^business_concept_id and c.status == ^status_published
      )

    result =
      Multi.new()
      |> Multi.update_all(:versioned, query, set: [status: BusinessConcept.status().versioned])
      |> Multi.update(
        :published,
        BusinessConceptVersion.update_status_changeset(business_concept_version, attrs)
      )
      |> Repo.transaction()

    case result do
      {:ok, %{published: %BusinessConceptVersion{business_concept_id: business_concept_id}}} ->
        params = retrieve_last_bc_version_params(business_concept_id)
        index_business_concept_versions(business_concept_id, params)
        result

      _ ->
        result
    end
  end

  defp index_business_concept_versions(business_concept_id, params) do
    business_concept_id
    |> list_business_concept_versions(nil)
    |> Enum.map(fn(bv) ->
        case params do
          params when params == %{} -> bv
          params -> Map.merge(bv, params)
        end
      end
    )
    |> Enum.each(&@search_service.put_search/1)
  end

  defp retrieve_last_bc_version_params(business_concept_id) do
    default_map = %{"link_count" => 0, "q_rule_count" => 0}
    query = %{
      query: %{term: %{"business_concept_id" => business_concept_id}},
      sort: [%{"version" => %{"order" => "desc"}}],
      size: "1"
    }

    @search_service.search("business_concept", query)
      |> parse_params_result(default_map)
  end

  defp parse_params_result([], default_map), do: parse_map_to_atom(default_map)
  #I only expect one element
  defp parse_params_result([result|_tail], default_map) do
    result
      |> Map.take(Map.keys(default_map))
      |> Map.merge(default_map, fn _k, v1, v2 ->
        v1 || v2
      end)
      |> parse_map_to_atom
  end

  defp parse_map_to_atom(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), v} end)
  end

  def reject_business_concept_version(%BusinessConceptVersion{} = business_concept_version, attrs) do
    result =
      business_concept_version
      |> BusinessConceptVersion.reject_changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated_version} ->
        business_concept_id = updated_version.business_concept_id
        params = retrieve_last_bc_version_params(business_concept_id)
        index_business_concept_versions(business_concept_id, params)
        result

      _ ->
        result
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking business_concept changes.

  ## Examples

      iex> change_business_concept(business_concept)
      %Ecto.Changeset{source: %BusinessConcept{}}

  """
  def change_business_concept(%BusinessConcept{} = business_concept) do
    BusinessConcept.changeset(business_concept, %{})
  end

  alias TdBg.BusinessConcepts.BusinessConceptVersion

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
  Returns the list of business_concept_versions.

  ## Examples

      iex> list_all_business_concept_versions()
      [%BusinessConceptVersion{}, ...]

  """
  def find_business_concept_versions(filter) do
    query =
      BusinessConceptVersion
      |> join(:left, [v], _ in assoc(v, :business_concept))
      |> preload([_, c], business_concept: c)
      |> order_by(asc: :version)

    query =
      case Map.has_key?(filter, :id) && length(filter.id) > 0 do
        true ->
          id = Map.get(filter, :id)
          query |> where([_v, c], c.id in ^id)

        _ ->
          query
      end

    query =
      case Map.has_key?(filter, :status) && length(filter.status) > 0 do
        true ->
          status = Map.get(filter, :status)
          query |> where([v, _c], v.status in ^status)

        _ ->
          query
      end

    query |> Repo.all()
  end

  @doc """
  Returns the list of business_concept_versions of a
  business_concept

  ## Examples

      iex> list_business_concept_versions(business_concept_id)
      [%BusinessConceptVersion{}, ...]

  """
  def list_business_concept_versions(business_concept_id, status) do
    BusinessConceptVersion
    |> join(:left, [v], _ in assoc(v, :business_concept))
    |> join(:left, [v, c], _ in assoc(c, :domain))
    |> preload([_, c, d], business_concept: {c, domain: d})
    |> where([_, c], c.id == ^business_concept_id)
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
    |> preload([_, c, d], business_concept: {c, domain: d})
    |> where([v, _], v.id == ^id)
    |> Repo.one!()
  end

  @doc """
  Deletes a BusinessCocneptVersion.

  ## Examples

      iex> delete_business_concept_version(data_structure)
      {:ok, %BusinessCocneptVersion{}}

      iex> delete_business_concept_version(data_structure)
      {:error, %Ecto.Changeset{}}

  """
  def delete_business_concept_version(%BusinessConceptVersion{} = business_concept_version) do
    if business_concept_version.version == 1 do
      Multi.new()
      |> Multi.delete(:business_concept_version, business_concept_version)
      |> Multi.delete(:business_concept, business_concept_version.business_concept)
      |> Repo.transaction()
      |> case do
        {:ok,
         %{
           business_concept: %BusinessConcept{},
           business_concept_version: %BusinessConceptVersion{} = version
         }} ->
          @search_service.delete_search(business_concept_version)
          {:ok, version}
      end
    else
      Multi.new()
      |> Multi.delete(:business_concept_version, business_concept_version)
      |> Multi.update(
        :current,
        BusinessConceptVersion.current_changeset(business_concept_version)
      )
      |> Repo.transaction()
      |> case do
        {:ok,
         %{
           business_concept_version: %BusinessConceptVersion{} = deleted_version,
           current: %BusinessConceptVersion{} = current_version
         }} ->
          @search_service.delete_search(deleted_version)
          {:ok, current_version}
      end
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking business_concept_version changes.

  ## Examples

      iex> change_business_concept_version(business_concept_version)
      %Ecto.Changeset{source: %BusinessConceptVersion{}}

  """
  def change_business_concept_version(%BusinessConceptVersion{} = business_concept_version) do
    BusinessConceptVersion.changeset(business_concept_version, %{})
  end

  defp map_keys_to_atoms(key_values) do
    Map.new(
      Enum.map(key_values, fn
        {key, value} when is_binary(key) -> {String.to_existing_atom(key), value}
        {key, value} when is_atom(key) -> {key, value}
      end)
    )
  end

  defp attrs_keys_to_atoms(key_values) do
    map = map_keys_to_atoms(key_values)

    case map.business_concept do
      %BusinessConcept{} -> map
      %{} = concept -> Map.put(map, :business_concept, map_keys_to_atoms(concept))
      _ -> map
    end
  end

  defp raise_error_if_no_content_schema(attrs) do
    if not Map.has_key?(attrs, @content_schema) do
      raise "Content Schema is not defined for Business Concept"
    end

    attrs
  end

  defp add_content_if_not_exist(attrs) do
    if not Map.has_key?(attrs, @content) do
      Map.put(attrs, @content, %{})
    else
      attrs
    end
  end

  defp validate_new_concept(attrs) do
    changeset = BusinessConceptVersion.create_changeset(%BusinessConceptVersion{}, attrs)
    Map.put(attrs, @changeset, changeset)
  end

  defp validate_concept(attrs, %BusinessConceptVersion{} = business_concept_version) do
    changeset = BusinessConceptVersion.update_changeset(business_concept_version, attrs)
    Map.put(attrs, @changeset, changeset)
  end

  defp merge_content_with_concept(attrs, %BusinessConceptVersion{} = business_concept_version) do
    content = Map.get(attrs, @content)
    concept_content = Map.get(business_concept_version, :content, %{})
    new_content = Map.merge(concept_content, content)
    Map.put(attrs, @content, new_content)
  end

  defp set_content_defaults(attrs) do
    content = Map.get(attrs, @content)
    content_schema = Map.get(attrs, @content_schema)
    new_content = set_default_values(content, content_schema)
    Map.put(attrs, @content, new_content)
  end

  defp set_default_values(content, [tails | head]) do
    content
    |> set_default_value(tails)
    |> set_default_values(head)
  end

  defp set_default_values(content, []), do: content

  defp set_default_value(content, %{"name" => name, "default" => default}) do
    case content[name] do
      nil ->
        content |> Map.put(name, default)

      _ ->
        content
    end
  end

  defp set_default_value(content, %{}), do: content

  defp validate_concept_content(attrs) do
    changeset = Map.get(attrs, @changeset)

    if changeset.valid? do
      do_validate_concept_content(attrs)
    else
      attrs
    end
  end

  defp do_validate_concept_content(attrs) do
    content = Map.get(attrs, @content)
    content_schema = Map.get(attrs, @content_schema)
    ecto_types = get_ecto_types(content_schema)

    changeset =
      {content, ecto_types}
      |> Changeset.cast(content, Map.keys(ecto_types))
      |> validate_content(content_schema)

    if not changeset.valid? do
      Map.put(attrs, @changeset, changeset)
    else
      attrs
    end
  end

  defp get_ecto_types(content_schema) do
    item_mapping = fn item ->
      name = item |> Map.get("name")
      type = item |> Map.get("type")
      {String.to_atom(name), get_ecto_type(type)}
    end

    content_schema
    |> Enum.map(item_mapping)
    |> Map.new()
  end

  defp get_ecto_type(type) do
    case type do
      @string -> :string
      @list -> :string
      @variable_list -> {:array, :string}
    end
  end

  defp validate_content(changeset, %{} = content_item) do
    changeset
    |> validate_required(content_item)
    |> validate_max_length(content_item)
    |> validate_inclusion(content_item)
  end

  defp validate_content(changeset, [tail | head]) do
    changeset
    |> validate_content(tail)
    |> validate_content(head)
  end

  defp validate_content(changeset, []), do: changeset

  defp validate_required(changeset, %{"name" => name, "required" => true}) do
    Changeset.validate_required(changeset, [String.to_atom(name)])
  end

  defp validate_required(changeset, %{}), do: changeset

  defp validate_max_length(changeset, %{"name" => name, "max_size" => max_size}) do
    Changeset.validate_length(changeset, String.to_atom(name), max: max_size)
  end

  defp validate_max_length(changeset, %{}), do: changeset

  defp validate_inclusion(changeset,
    %{"type" => "list", "meta" => %{"role" => _rolename}}), do: changeset
  defp validate_inclusion(changeset, %{"name" => name, "type" => "list", "values" => values}) do
    Changeset.validate_inclusion(changeset, String.to_atom(name), values)
  end

  defp validate_inclusion(changeset, %{}), do: changeset

  defp update_concept(attrs) do
    changeset = Map.get(attrs, @changeset)

    if changeset.valid? do
      Repo.update(changeset)
    else
      {:error, changeset}
    end
  end

  defp insert_concept(attrs) do
    changeset = Map.get(attrs, @changeset)

    if changeset.valid? do
      Repo.insert(changeset)
    else
      {:error, changeset}
    end
  end

  defp version_concept(attrs, business_concept_version) do
    changeset = Map.get(attrs, @changeset)

    if changeset.valid? do
      Multi.new()
      |> Multi.update(
        :not_current,
        BusinessConceptVersion.not_anymore_current_changeset(business_concept_version)
      )
      |> Multi.insert(:current, changeset)
      |> Repo.transaction()
    else
      {:error, %{current: changeset}}
    end
  end

  alias TdBg.BusinessConcepts.BusinessConceptAlias

  @doc """
  Returns the list of business_concept_aliases
  of a business_concept

  ## Examples

      iex> list_business_concept_aliases(123)
      [%BusinessConceptAlias{}, ...]

  """
  def list_business_concept_aliases(business_concept_id) do
    BusinessConceptAlias
    |> where([v], v.business_concept_id == ^business_concept_id)
    |> order_by(desc: :business_concept_id)
    |> Repo.all()
  end

  @doc """
  Gets a single business_concept_alias.

  Raises `Ecto.NoResultsError` if the Business concept alias does not exist.

  ## Examples

      iex> get_business_concept_alias!(123)
      %BusinessConceptAlias{}

      iex> get_business_concept_alias!(456)
      ** (Ecto.NoResultsError)

  """
  def get_business_concept_alias!(id), do: Repo.get!(BusinessConceptAlias, id)

  @doc """
  Creates a business_concept_alias.

  ## Examples

      iex> create_business_concept_alias(%{field: value})
      {:ok, %BusinessConceptAlias{}}

      iex> create_business_concept_alias(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_business_concept_alias(attrs \\ %{}) do
    %BusinessConceptAlias{}
    |> BusinessConceptAlias.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a BusinessConceptAlias.

  ## Examples

      iex> delete_business_concept_alias(business_concept_alias)
      {:ok, %BusinessConceptAlias{}}

      iex> delete_business_concept_alias(business_concept_alias)
      {:error, %Ecto.Changeset{}}

  """
  def delete_business_concept_alias(%BusinessConceptAlias{} = business_concept_alias) do
    Repo.delete(business_concept_alias)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking business_concept_alias changes.

  ## Examples

      iex> change_business_concept_alias(business_concept_alias)
      %Ecto.Changeset{source: %BusinessConceptAlias{}}

  """
  def change_business_concept_alias(%BusinessConceptAlias{} = business_concept_alias) do
    BusinessConceptAlias.changeset(business_concept_alias, %{})
  end

  def get_business_concept_by_name(name) do
    # Repo.all from r in BusinessConceptVersion, where:
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

  def check_valid_related_to(_type, []), do: {:valid_related_to}

  def check_valid_related_to(type, ids) do
    input_count = length(ids)
    actual_count = count_published_business_concepts(type, ids)
    if input_count == actual_count, do: {:valid_related_to}, else: {:not_valid_related_to}
  end
end
