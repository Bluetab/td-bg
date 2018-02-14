defmodule TrueBG.BusinessConcepts do
  @moduledoc """
  The BusinessConcepts context.
  """

  import Ecto.Query, warn: false
  alias TrueBG.Repo
  alias TrueBG.BusinessConcepts.BusinessConcept
  alias Ecto.Changeset

  @changeset "changeset"
  @content "content"
  @content_schema "content_schema"

  @string "string"
  @list "list"
  @variable_list "variable_list"

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
  Returns children of data domain id passed as argument
  """
  def list_children_business_concept(id) do
    query = from bconcept in BusinessConcept,
                 where: bconcept.data_domain_id == ^id
    Repo.all(query)
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

  def update_status_to_versioned(published_business_concept_id) do
    query = from c in BusinessConcept,
    where: c.last_version_id == ^published_business_concept_id
    Repo.update_all query, set: [status: BusinessConcept.status.versioned]
  end

  def update_last_version(new_id, old_id) do
    query = from c in BusinessConcept,
    where: c.last_version_id == ^old_id or c.id == ^old_id
    Repo.update_all query, set: [last_version_id: new_id]
  end

  @doc """
  Rejects a business_concept.

  ## Examples

      iex> reject_business_concept(business_concept, %{reject_reason: reject_reason})
      {:ok, %BusinessConcept{}}

  """
  def reject_business_concept(%BusinessConcept{} = business_concept, attrs) do
    business_concept
    |> BusinessConcept.reject_changeset(attrs)
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

  defp validate_new_concept(attrs) do
    changeset = BusinessConcept.create_changeset(%BusinessConcept{}, attrs)
    Map.put(attrs, @changeset, changeset)
  end

  defp validate_concept(attrs, %BusinessConcept{} = business_concept) do
      changeset = BusinessConcept.update_changeset(business_concept, attrs)
      Map.put(attrs, @changeset, changeset)
  end

  defp merge_content(attrs, %BusinessConcept{} = business_concept) do
    content = Map.get(attrs, @content)
    concept_content = Map.get(business_concept, :content, %{})
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
