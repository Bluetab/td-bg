defmodule TrueBG.Taxonomies do
  @moduledoc """
  The Taxonomies context.
  """

  import Ecto.Query, warn: false
  alias TrueBG.Repo
  alias TrueBG.Taxonomies.BusinessConcept
  alias TrueBG.Taxonomies.DataDomain
  alias TrueBG.Taxonomies.DomainGroup
  alias TrueBG.Permissions.AclEntry
  alias Ecto.Changeset
  alias Ecto.Multi

  @doc """
  Returns the list of domain_groups.

  ## Examples

      iex> list_domain_groups()
      [%DomainGroup{}, ...]

  """
  def list_domain_groups do
    Repo.all(DomainGroup)
  end

  @doc """
  Returns the list of root domain_groups (no parent)
  """
  def list_root_domain_groups do
    query = from dg in DomainGroup,
                 where: is_nil(dg.parent_id)

    Repo.all(query)
  end

  @doc """
  Returns children of domain group id passed as argument
  """
  def list_domain_group_children(id) do
    query = from dg in DomainGroup,
                 where: dg.parent_id == ^id
    Repo.all(query)
  end

  @doc """
  """
  def list_children_data_domain(domain_group_id) do
    query = from dd in DataDomain,
            where: dd.domain_group_id == ^domain_group_id
    Repo.all(query)
  end

  @doc """
  Returns children of data domain id passed as argument
  """
  def list_children_business_concept(id) do
    query = from bconcept in BusinessConcept,
                 where: bconcept.data_domain_id == ^id
    Repo.all(query)
  end

  @doc """
  Gets a single domain_group.

  Raises `Ecto.NoResultsError` if the Domain group does not exist.

  ## Examples

      iex> get_domain_group!(123)
      %DomainGroup{}

      iex> get_domain_group!(456)
      ** (Ecto.NoResultsError)

  """
  def get_domain_group!(id), do: Repo.get!(DomainGroup, id)

  def get_domain_group(id), do: Repo.get(DomainGroup, id)

  def get_domain_group_by_name(name) do
    Repo.get_by(DomainGroup, name: name)
  end

  @doc """
  Creates a domain_group.

  ## Examples

      iex> create_domain_group(%{field: value})
      {:ok, %DomainGroup{}}

      iex> create_domain_group(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_domain_group(attrs \\ %{}) do
    %DomainGroup{}
    |> DomainGroup.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a domain_group.

  ## Examples

      iex> update_domain_group(domain_group, %{field: new_value})
      {:ok, %DomainGroup{}}

      iex> update_domain_group(domain_group, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_domain_group(%DomainGroup{} = domain_group, attrs) do
    domain_group
    |> DomainGroup.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a DomainGroup.

  ## Examples

      iex> delete_domain_group(domain_group)
      {:ok, %DomainGroup{}}

      iex> delete_domain_group(domain_group)
      {:error, %Ecto.Changeset{}}

  """
  def delete_domain_group(%DomainGroup{} = domain_group) do
    Multi.new
    |> Multi.delete_all(:acl_entry, from(acl in AclEntry, where: acl.resource_type == "domain_group" and acl.resource_id == ^domain_group.id))
    |> Multi.delete(:domain_group, domain_group)
    |> Repo.transaction
    |> case do
      {:ok, %{acl_entry: _acl_entry, domain_group: domain_group}} ->
        {:ok, domain_group}
     end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking domain_group changes.

  ## Examples

      iex> change_domain_group(domain_group)
      %Ecto.Changeset{source: %DomainGroup{}}

  """
  def change_domain_group(%DomainGroup{} = domain_group) do
    DomainGroup.changeset(domain_group, %{})
  end

  @doc """

  """
  def get_parent_id(nil) do
    {:error, nil}
  end
  def get_parent_id(%{"parent_id": nil}) do
    {:ok, nil}
  end
  def get_parent_id(%{"parent_id": parent_id}) do
    get_parent_id(get_domain_group(parent_id))
  end
  def get_parent_id(parent_id) do
    {:ok, parent_id}
  end

  @doc """
  Returns the list of data_domains.

  ## Examples

      iex> list_data_domains()
      [%DataDomain{}, ...]

  """
  def list_data_domains do
    Repo.all(DataDomain)
  end

  def get_data_domain_by_name(name) do
    Repo.get_by(DataDomain, name: name)
  end

  @doc """
  Gets a single data_domain.

  Raises `Ecto.NoResultsError` if the Data domain does not exist.

  ## Examples

      iex> get_data_domain!(123)
      %DataDomain{}

      iex> get_data_domain!(456)
      ** (Ecto.NoResultsError)

  """
  def get_data_domain!(id), do: Repo.get!(DataDomain, id)

  @doc """
  Creates a data_domain.

  ## Examples

      iex> create_data_domain(%{field: value})
      {:ok, %DataDomain{}}

      iex> create_data_domain(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_data_domain(attrs \\ %{}) do
    %DataDomain{}
    |> DataDomain.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a data_domain.

  ## Examples

      iex> update_data_domain(data_domain, %{field: new_value})
      {:ok, %DataDomain{}}

      iex> update_data_domain(data_domain, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_data_domain(%DataDomain{} = data_domain, attrs) do
    data_domain
    |> DataDomain.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a DataDomain.

  ## Examples

      iex> delete_data_domain(data_domain)
      {:ok, %DataDomain{}}

      iex> delete_data_domain(data_domain)
      {:error, %Ecto.Changeset{}}

  """
  def delete_data_domain(%DataDomain{} = data_domain) do
    Multi.new
    |> Multi.delete_all(:acl_entry, from(acl in AclEntry, where: acl.resource_type == "data_domain" and acl.resource_id == ^data_domain.id))
    |> Multi.delete(:data_domain, data_domain)
    |> Repo.transaction
    |> case do
         {:ok, %{acl_entry: _acl_entry, data_domain: data_domain}} ->
           {:ok, data_domain}
       end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking data_domain changes.

  ## Examples

      iex> change_data_domain(data_domain)
      %Ecto.Changeset{source: %DataDomain{}}

  """
  def change_data_domain(%DataDomain{} = data_domain) do
    DataDomain.changeset(data_domain, %{})
  end

  alias TrueBG.Taxonomies.BusinessConcept

  @valid "valid"
  @changeset "changeset"
  @content "content"
  @content_schema "content_schema"

  @string "string"
  @list "list"
  @variable_list "variable list"

  @doc """
  Returns the list of business_concepts.

  ## Examples

      iex> list_business_concepts()
      [%BusinessConcept{}, ...]

  """
  def list_business_concepts do
    Repo.all(BusinessConcept)
  end

  @doc """
  Gets a single business_concept.

  Raises `Ecto.NoResultsError` if the Business concept does not exist.

  ## Examples

      iex> get_business_concept!(123)
      %BusinessConcept{}

      iex> get_business_concept!(456)
      ** (Ecto.NoResultsError)

  """
  def get_business_concept!(id), do: Repo.get!(BusinessConcept, id)

  @doc """
  Creates a business_concept.

  ## Examples

      iex> create_business_concept(%{field: value})
      {:ok, %BusinessConcept{}}

      iex> create_business_concept(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_business_concept(attrs \\ %{}) do
    attrs
    |> attrs_keys_to_string
    |> content_schema_exists?
    |> initialize_attrs_state
    |> set_content_defaults
    |> validate_new_concept
    |> validate_concept_content
    |> insert_concept
  end

  @doc """
  Updates a business_concept.

  ## Examples

      iex> update_business_concept(business_concept, %{field: new_value})
      {:ok, %BusinessConcept{}}

      iex> update_business_concept(business_concept, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_business_concept(%BusinessConcept{} = business_concept, attrs) do
    attrs
    |> attrs_keys_to_string
    |> content_schema_exists?
    |> add_content_if_not_exist
    |> initialize_attrs_state
    |> merge_content(business_concept)
    |> set_content_defaults
    |> validate_concept(business_concept)
    |> validate_concept_content
    |> update_concept
  end

  @doc """
  Updates a business_concept status.

  ## Examples

      iex> update_business_concept_status(business_concept, %{status: new_status})
      {:ok, %BusinessConcept{}}

      iex> update_business_concept(business_concept, %{status: bad_status})
      {:error, %Ecto.Changeset{}}

  """
  def update_business_concept_status(%BusinessConcept{} = business_concept, attrs) do
    business_concept
    |> BusinessConcept.update_status_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a BusinessConcept.

  ## Examples

      iex> delete_business_concept(business_concept)
      {:ok, %BusinessConcept{}}

      iex> delete_business_concept(business_concept)
      {:error, %Ecto.Changeset{}}

  """
  def delete_business_concept(%BusinessConcept{} = business_concept) do
    Repo.delete(business_concept)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking business_concept changes.

  ## Examples

      iex> change_business_concept(business_concept)
      %Ecto.Changeset{source: %BusinessConcept{}}

  """
  def change_business_concept(%BusinessConcept{} = business_concept) do
    BusinessConcept.create_changeset(business_concept, %{})
  end

  defp attrs_keys_to_string(attrs) do
      keyword = Enum.map(attrs, fn
        {key, value} when is_binary(key) -> {key, value}
        {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      end)
      Map.new(keyword)
  end

  defp content_schema_exists?(attrs) do
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

  defp initialize_attrs_state(attrs) do
      attrs
      |> Map.put(@valid, true)
      |> Map.put(@changeset, nil)
  end

  defp validate_new_concept(attrs) do
    if Map.get(attrs, @valid) do
      changeset = BusinessConcept.create_changeset(%BusinessConcept{}, attrs)
      case changeset.valid? do
        false ->
          attrs
          |> Map.put(@valid, false)
          |> Map.put(@changeset, changeset)
        _ -> Map.put(attrs, @changeset, changeset)
      end
    else
      attrs
    end
  end

  defp validate_concept(attrs, %BusinessConcept{} = business_concept) do
    if Map.get(attrs, @valid) do
      changeset = BusinessConcept.update_changeset(business_concept, attrs)
      case changeset.valid? do
        false ->
          attrs
          |> Map.put(@valid, false)
          |> Map.put(@changeset, changeset)
        _ -> Map.put(attrs, @changeset, changeset)
      end
    else
      attrs
    end
  end

  defp merge_content(attrs, %BusinessConcept{} = business_concept) do
    if Map.get(attrs, @valid) do
      content = Map.get(attrs, @content)
      concept_content = Map.get(business_concept, :content, %{})
      new_content = Map.merge(concept_content, content)
      Map.put(attrs, @content, new_content)
    else
      attrs
    end
  end

  defp set_content_defaults(attrs) do
    valid = Map.get(attrs, @valid)
    if valid do
      content = set_default_values(Map.get(attrs, @content), Map.get(attrs, @content_schema))
      Map.put(attrs, @content, content)
    else
      attrs
    end
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
    if Map.get(attrs, @valid) do
      content = Map.get(attrs, @content)
      content_schema = Map.get(attrs, @content_schema)
      ecto_types = get_ecto_types(content_schema)
      changeset = {content, ecto_types}
        |> Changeset.cast(content, Map.keys(ecto_types))
        |> validate_content(content_schema)
      case changeset.valid? do
        false ->
          attrs
          |> Map.put(@valid, false)
          |> Map.put(@changeset, changeset)
        _ -> attrs
      end
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
    if Map.get(attrs, @valid) do
      Repo.update(Map.get(attrs, @changeset))
    else
      {:error, Map.get(attrs, @changeset)}
    end
  end

  defp insert_concept(attrs) do
    if Map.get(attrs, @valid) do
      Repo.insert(Map.get(attrs, @changeset))
    else
      {:error, Map.get(attrs, @changeset)}
    end
  end

end
