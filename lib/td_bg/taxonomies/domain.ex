defmodule TdBg.Taxonomies.Domain do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias TdBg.Searchable
  alias TdBg.Taxonomies
  alias TdBg.Taxonomies.Domain
  alias TdBg.Templates.Template

  @behaviour Searchable

  schema "domains" do
    field :description, :string
    field :type, :string
    field :name, :string
    belongs_to :parent, Domain

    timestamps()

    many_to_many :templates, Template, join_through: "domains_templates", on_replace: :delete, on_delete: :delete_all
  end

  @doc false
  def changeset(%Domain{} = domain, attrs) do
    domain
      |> cast(attrs, [:name, :type, :description, :parent_id])
      |> validate_required([:name])
  end

  @doc false
  def delete_changeset(%Domain{} = domain) do
    domain
    |> cast(%{}, [])
  end

  def search_fields(%Domain{} = domain) do
    parent_ids = Taxonomies.get_parent_ids(domain, false)
    %{name: domain.name, description: domain.description, parent_id: domain.parent_id, parent_ids: parent_ids}
  end

  def index_name do
    "domain"
  end

end
