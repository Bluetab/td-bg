defmodule TdBg.BusinessConcepts.BusinessConcept do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias TdBg.Taxonomies.DataDomain
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.BusinessConcepts.BusinessConceptAlias
  alias TdBg.Permissions.Role

  @permissions %{
    admin:   [:create, :update, :send_for_approval, :delete, :publish, :reject,
              :deprecate, :view_versions, :manage_alias],
    publish: [:create, :update, :send_for_approval, :delete, :publish, :reject,
              :deprecate, :view_versions, :manage_alias],
    create:  [:create, :update, :send_for_approval, :delete, :view_versions],
    watch:   [:view_versions]
  }

  @status %{draft: "draft",
            pending_approval: "pending_approval",
            rejected: "rejected",
            published: "published",
            versioned: "versioned",
            deprecated: "deprecated"}

  schema "business_concepts" do
    belongs_to :data_domain, DataDomain
    field :type, :string
    field :last_change_by, :integer
    field :last_change_at, :utc_datetime

    has_many :versions, BusinessConceptVersion
    has_many :aliases, BusinessConceptAlias

    timestamps()
  end

  def get_permissions do
    @permissions
  end

  def get_allowed_version_status_by_role(role) do
    if role == Role.create or role == Role.watch do
      [BusinessConcept.status.published,
       BusinessConcept.status.versioned,
       BusinessConcept.status.deprecated]
    else
      [BusinessConcept.status.draft,
       BusinessConcept.status.pending_approval,
       BusinessConcept.status.rejected,
       BusinessConcept.status.published,
       BusinessConcept.status.versioned,
       BusinessConcept.status.deprecated]
    end
  end

  def status do
    @status
  end

  @doc false
  def changeset(%BusinessConcept{} = business_concept, attrs) do
    business_concept
    |> cast(attrs, [:data_domain_id, :type, :last_change_by, :last_change_at])
    |> validate_required([:data_domain_id, :type, :last_change_by, :last_change_at])
  end

end
