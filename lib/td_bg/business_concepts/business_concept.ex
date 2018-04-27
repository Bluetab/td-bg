defmodule TdBg.BusinessConcepts.BusinessConcept do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias TdBg.Taxonomies.Domain
  alias TdBg.Permissions.Permission
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.BusinessConcepts.BusinessConceptAlias

  @status %{draft: "draft",
            pending_approval: "pending_approval",
            rejected: "rejected",
            published: "published",
            versioned: "versioned",
            deprecated: "deprecated"}

  schema "business_concepts" do
    belongs_to :domain, Domain
    field :type, :string
    field :last_change_by, :integer
    field :last_change_at, :utc_datetime

    has_many :versions, BusinessConceptVersion
    has_many :aliases, BusinessConceptAlias

    timestamps()
  end

  def status do
    @status
  end

  def status_values do
    @status |> Map.values
  end

  def permissions_to_status do
    permissions = Permission.permissions
    status = BusinessConcept.status
    %{permissions.view_draft_business_concepts => status.draft,
      permissions.view_approval_pending_business_concepts => status.pending_approval,
      permissions.view_published_business_concepts => status.published,
      permissions.view_versioned_business_concepts => status.versioned,
      permissions.view_rejected_business_concepts => status.rejected,
      permissions.view_deprecated_business_concepts => status.deprecated}
  end

  @doc false
  def changeset(%BusinessConcept{} = business_concept, attrs) do
    business_concept
    |> cast(attrs, [:domain_id, :type, :last_change_by, :last_change_at])
    |> validate_required([:domain_id, :type, :last_change_by, :last_change_at])
  end

end
