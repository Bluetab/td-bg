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
  alias TdBg.Utils.CollectionUtils

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

  def get_template_by_name(name) do
    Repo.one from r in Template, where: r.name == ^name
  end

  # TODO: unit test this method
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
    attrs = CollectionUtils.atomize_keys(attrs)
    case get_default_template() do
      nil ->
          attrs = Map.put(attrs, :is_default, true)
          %Template{}
          |> Template.changeset(attrs)
          |> Repo.insert()

      default_template ->
        do_create_template(default_template, attrs)
    end
  end

  def do_create_template(default_template, attrs) do
    case Map.get(attrs, :is_default) do
      true ->
        default_template
        |> Template.changeset(%{is_default: false})
        |> Repo.update()
        %Template{}
        |> Template.changeset(attrs)
        |> Repo.insert()
      false ->
        %Template{}
        |> Template.changeset(attrs)
        |> Repo.insert()
    end
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
    attrs = CollectionUtils.atomize_keys(attrs)
    case get_default_template() do
      nil ->
        attrs = Map.put(attrs, :is_default, true)
        template
        |> Template.changeset(attrs)
        |> Repo.update()

      default_template ->
        case default_template.id == template.id do
          true ->
            template
            |> Template.changeset(attrs)
            |> Repo.update()

          false ->
            do_update_template(default_template, template, attrs)
        end
    end
  end

  def do_update_template(default_template, template, attrs) do
    case Map.get(attrs, :is_default) do
      true ->
        default_template
        |> Template.changeset(%{is_default: false})
        |> Repo.update()
        template
        |> Template.changeset(attrs)
        |> Repo.update()
      false ->
        template
        |> Template.changeset(attrs)
        |> Repo.update()
    end
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
    delresp = Repo.delete(template)
    case get_default_template() do
      nil ->
        do_delete_template()
      _ -> nil
    end
    delresp
  end

  defp do_delete_template do
    case get_any_template() do
      nil -> nil
      template ->
        template
        |> Template.changeset(%{is_default: true})
        |> Repo.update()
    end

  end

  defp get_any_template do
    Repo.one from r in Template, limit: 1
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

end
