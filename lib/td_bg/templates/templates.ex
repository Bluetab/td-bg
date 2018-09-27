defmodule TdBg.Templates do
  @moduledoc """
  The Templates context.
  """

  import Ecto.Query, warn: false
  alias TdBg.Repo

  alias Ecto.Changeset
  alias TdBg.Taxonomies
  alias TdBg.Taxonomies.Domain
  alias TdBg.Templates.Template

  @string "string"
  @list "list"
  @variable_list "variable_list"

  @doc """
  Returns the list of templates.

  ## Examples

      iex> list_templates()
      [%Template{}, ...]

  """
  def list_templates do
    Repo.all(Template)
  end

  @doc """
  Gets a single template.

  Raises `Ecto.NoResultsError` if the Template does not exist.

  ## Examples

      iex> get_template!(123)
      %Template{}

      iex> get_template!(456)
      ** (Ecto.NoResultsError)

  """
  def get_template!(id), do: Repo.get!(Template, id)

  def get_template_by_name!(name) do
    Repo.one! from r in Template, where: r.name == ^name
  end

  def get_template_by_name(name) do
    Repo.one from r in Template, where: r.name == ^name
  end

  def get_default_template do
    Repo.one from r in Template, where: r.is_default == true, limit: 1
  end

  @doc """
  Creates a template.

  ## Examples

      iex> create_template(%{field: value})
      {:ok, %Template{}}

      iex> create_template(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_template(attrs \\ %{}) do
    %Template{}
    |> Template.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a template.

  ## Examples

      iex> update_template(template, %{field: new_value})
      {:ok, %Template{}}

      iex> update_template(template, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_template(%Template{} = template, attrs) do
    template
    |> Template.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Template.

  ## Examples

      iex> delete_template(template)
      {:ok, %Template{}}

      iex> delete_template(template)
      {:error, %Ecto.Changeset{}}

  """
  def delete_template(%Template{} = template) do
    Repo.delete(template)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking template changes.

  ## Examples

      iex> change_template(template)
      %Ecto.Changeset{source: %Template{}}

  """
  def change_template(%Template{} = template) do
    Template.changeset(template, %{})
  end

  def get_domain_templates(%Domain{} = domain) do
    get_domain_templates(%{domain_id: domain.id}, [])
  end
  def get_domain_templates(%{domain_id: nil}, templates), do: templates |> Enum.uniq_by(&(&1.id))
  def get_domain_templates(%{domain_id: domain_id}, templates) do
    domain = domain_id
      |> Taxonomies.get_domain!
      |> Repo.preload([:templates])
    templates = templates ++ get_templates_from_domain(domain)
    get_domain_templates(%{domain_id: domain.parent_id}, templates)
  end

  defp get_templates_from_domain(%Domain{} = domain) do
    domain
    |> Map.get(:templates)
  end

  def add_templates_to_domain(%Domain{} = domain, templates) do
    domain
    |> Repo.preload(:templates)
    |> Changeset.change
    |> Changeset.put_assoc(:templates, templates)
    |> Repo.update!
  end

  def count_related_domains(id) do
    count = Repo.one from r in "domains_templates", select: count(r.template_id), where: r.template_id == ^id
    {:count, :domain, count}
  end

  def build_changeset(content, content_schema) do
    changeset_fields = get_changeset_fields(content_schema)
    changeset = {content, changeset_fields}
    changeset
      |> Changeset.cast(content, Map.keys(changeset_fields))
      |> add_content_validation(content_schema)
  end

  defp get_changeset_fields(content_schema) do
    item_mapping = fn item ->
      name = item |> Map.get("name")
      type = item |> Map.get("type")
      {String.to_atom(name), get_changeset_field(type)}
    end

    content_schema
    |> Enum.map(item_mapping)
    |> Map.new()
  end

  defp get_changeset_field(type) do
    case type do
      @string -> :string
      @list -> :string
      @variable_list -> {:array, :string}
    end
  end

  defp add_content_validation(changeset, %{} = content_item) do
    changeset
    |> add_require_validation(content_item)
    |> add_max_length_validation(content_item)
    |> add_inclusion_validation(content_item)
  end

  defp add_content_validation(changeset, [tail | head]) do
    changeset
    |> add_content_validation(tail)
    |> add_content_validation(head)
  end

  defp add_content_validation(changeset, []), do: changeset

  defp add_require_validation(changeset, %{"name" => name, "required" => true}) do
    Changeset.validate_required(changeset, [String.to_atom(name)])
  end

  defp add_require_validation(changeset, %{}), do: changeset

  defp add_max_length_validation(changeset, %{"name" => name, "max_size" => max_size}) do
    Changeset.validate_length(changeset, String.to_atom(name), max: max_size)
  end

  defp add_max_length_validation(changeset, %{}), do: changeset

  defp add_inclusion_validation(changeset,
    %{"type" => "list", "meta" => %{"role" => _rolename}}), do: changeset
  defp add_inclusion_validation(changeset, %{"name" => name, "type" => "list", "values" => values}) do
    Changeset.validate_inclusion(changeset, String.to_atom(name), values)
  end

  defp add_inclusion_validation(changeset, %{}), do: changeset

end
