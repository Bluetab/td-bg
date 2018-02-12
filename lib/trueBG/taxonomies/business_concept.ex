defmodule TrueBG.Taxonomies.BusinessConcept do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias TrueBG.Taxonomies.DataDomain
  alias TrueBG.Taxonomies.BusinessConcept

  @permissions %{
    admin:   [:create, :update, :send_for_approval, :delete, :publish, :reject,
              :deprecate, :see_draft, :see_published],
    publish: [:create, :update, :send_for_approval, :delete, :publish, :reject,
              :deprecate, :see_draft, :see_published],
    create:  [:create, :update, :send_for_approval, :delete, :see_draft,
              :see_published],
    watch:   [:see_published]
  }

  @status [:draft, :pending_approval, :published]

  schema "business_concepts" do
    field :content, :map
    field :type, :string
    field :name, :string
    field :description, :string
    field :modifier, :integer
    field :last_change, :utc_datetime
    belongs_to :data_domain, DataDomain
    field :status, :string
    field :version, :integer

    timestamps()
  end

  def get_permissions do
    @permissions
  end

  @doc false
  def changeset(%BusinessConcept{} = business_concept, attrs) do
    business_concept
    |> cast(attrs, [:content, :type, :name, :description, :modifier,
                    :last_change, :data_domain_id, :status, :version])
    |> validate_required([:content, :type, :name, :modifier, :last_change,
                          :data_domain_id, :status, :version])
    |> validate_length(:name, max: 255)
    |> validate_length(:description, max: 500)
    |> unique_constraint(:business_concept,
                                    name: :index_business_concept_by_name_type)
  end

  @doc false
  def status_changeset(%BusinessConcept{} = business_concept, attrs) do
    business_concept
    |> cast(attrs, [:status])
    |> validate_required([:status])
    |> validate_inclusion(:status, Enum.map(@status, &Atom.to_string(&1)))
  end

  def get_status do
    @status
  end

  def draft do
    :draft
  end

  def pending_approval do
    :pending_approval
  end

  def published do
    :published
  end

end
