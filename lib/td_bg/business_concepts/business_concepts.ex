defmodule TdBg.BusinessConcepts do
  @moduledoc """
  The BusinessConcepts context.
  """

  import Ecto.Query, warn: false
  alias TdBg.Repo
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias Ecto.Changeset
  alias Ecto.Multi

  @changeset :changeset
  @content :content
  @content_schema :content_schema

  @string "string"
  @list "list"
  @variable_list "variable_list"

  @doc """
  count  business conceps of indicated type name
  and status

  """
  def exist_business_concept_by_type_and_name?(type, name, exclude_id \\ nil)
  def exist_business_concept_by_type_and_name?(type, name, _exclude_id) when is_nil(name) or is_nil(type),  do: {:ok, 0}
  def exist_business_concept_by_type_and_name?(type, name, exclude_id) do
    status = [BusinessConcept.status.versioned]
    count = BusinessConceptVersion
    |> join(:left, [v], _ in assoc(v, :business_concept))
    |> where([v, c], c.type == ^type and v.name == ^name and v.status not in ^status)
    |> exlude_business_id_where(exclude_id)
    |> select([v, _], count(v.id))
    |> Repo.one!
    {:ok, count}                                                    #                                                     BusinessConcept.published])
  end

  defp exlude_business_id_where(query, nil), do: query
  defp exlude_business_id_where(query, exclude_id) do
    query |> where([_, c], c.id != ^exclude_id)
  end

  @doc """
  Returns children of data domain id passed as argument
  """
  def get_data_domain_children_versions!(data_domain_id) do
    BusinessConceptVersion
    |> join(:left, [v], _ in assoc(v, :business_concept))
    |> preload([_, c], [business_concept: c])
    |> where([_, c], c.data_domain_id == ^data_domain_id)
    |> Repo.all
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
     |> join(:left, [v], _ in assoc(v, :business_concept))
     |> preload([_, c], [business_concept: c])
     |> where([_, c], c.id == ^business_concept_id)
     |> order_by(desc: :version)
     |> limit(1)
     |> Repo.one!
   end

  @doc """
  Creates a business_concept.

  ## Examples

      iex> create_business_concept_version(%{field: value})
      {:ok, %BusinessConceptVersion{}}

      iex> create_business_concept_version(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_business_concept_version(attrs \\ %{}) do
    attrs
    |> attrs_keys_to_atoms
    |> raise_error_if_no_content_schema
    |> set_content_defaults
    |> validate_new_concept
    |> validate_concept_content
    |> insert_concept
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
    attrs
    |> attrs_keys_to_atoms
    |> raise_error_if_no_content_schema
    |> add_content_if_not_exist
    |> merge_content_with_concept(business_concept_version)
    |> set_content_defaults
    |> validate_concept(business_concept_version)
    |> validate_concept_content
    |> update_concept
  end

  def update_business_concept_version_status(%BusinessConceptVersion{} = business_concept_version, attrs) do
    business_concept_version
    |> BusinessConceptVersion.update_status_changeset(attrs)
    |> Repo.update()
  end

  def publish_business_concept_version(business_concept_version) do
    status_published = BusinessConcept.status.published
    attrs = %{status: status_published}

    business_concept_id = business_concept_version.business_concept.id
    query = from c in BusinessConceptVersion,
    where: c.business_concept_id == ^business_concept_id and
           c.status == ^status_published

    Multi.new
    |> Multi.update_all(:versioned, query, [set: [status: BusinessConcept.status.versioned]])
    |> Multi.update(:published, BusinessConceptVersion.update_status_changeset(business_concept_version, attrs))
    |> Repo.transaction
  end

  def reject_business_concept_version(%BusinessConceptVersion{} = business_concept_version, attrs) do
    business_concept_version
    |> BusinessConceptVersion.reject_changeset(attrs)
    |> Repo.update()
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

      iex> list_all_business_concept_versions()
      [%BusinessConceptVersion{}, ...]

  """
  def list_all_business_concept_versions do
    BusinessConceptVersion
    |> join(:left, [v], _ in assoc(v, :business_concept))
    |> preload([_, c], [business_concept: c])
    |> order_by(asc: :version)
    |> Repo.all
  end

  @doc """
  Returns the list of business_concept_versions of a
  business_concept

  ## Examples

      iex> list_business_concept_versions(business_concept_id)
      [%BusinessConceptVersion{}, ...]

  """
  def list_business_concept_versions(business_concept_id) do
    BusinessConceptVersion
    |> join(:left, [v], _ in assoc(v, :business_concept))
    |> preload([_, c], [business_concept: c])
    |> where([_, c], c.id == ^business_concept_id)
    |> order_by(desc: :version)
    |> Repo.all
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
    |> preload([_, c], [business_concept: c])
    |> where([v, _], v.id == ^id)
    |> Repo.one!
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
       Multi.new
       |> Multi.delete(:business_concept_version, business_concept_version)
       |> Multi.delete(:business_concept, business_concept_version.business_concept)
       |> Repo.transaction
       |> case do
         {:ok, %{business_concept: %BusinessConcept{},
                 business_concept_version: %BusinessConceptVersion{} = version}} ->
           {:ok, version}
       end
     else
       Repo.delete(business_concept_version)
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
    Map.new((Enum.map(key_values, fn
      {key, value} when is_binary(key) -> {String.to_existing_atom(key), value}
      {key, value} when is_atom(key) -> {key, value}
    end)))
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

  defp set_default_values(content, [tails|head]) do
    content
      |> set_default_value(tails)
      |> set_default_values(head)
  end
  defp set_default_values(content, []), do: content

  defp set_default_value(content, %{"name" => name, "default" => default}) do
    case content[name] do
      nil ->
        content |> Map.put(name, default)
      _ -> content
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
    changeset = {content, ecto_types}
    |> Changeset.cast(content, Map.keys(ecto_types))
    |> validate_content(content_schema)

    if not changeset.valid? do
      Map.put(attrs, @changeset, changeset)
    else
      attrs
    end
  end

  defp get_ecto_types(content_schema) do
    item_mapping = fn(item) ->
      name = item |> Map.get("name")
      type = item |> Map.get("type")
      {String.to_atom(name), get_ecto_type(type)}
    end
    content_schema
      |> Enum.map(item_mapping)
      |> Map.new
  end

  defp  get_ecto_type(type) do
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
  defp validate_content(changeset, [tail|head]) do
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

end
