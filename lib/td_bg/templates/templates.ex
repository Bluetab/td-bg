defmodule TdBg.Templates do
  @moduledoc """
  The Templates context.
  """

  import Ecto.Query, warn: false
  alias TdBg.Repo

  alias TdBg.Templates.Template
  alias TdBg.Taxonomies.Domain
  alias Ecto.Changeset

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
    domain
    |> Repo.preload(:templates)
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
