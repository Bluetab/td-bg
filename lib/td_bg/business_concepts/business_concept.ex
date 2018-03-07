defmodule TdBG.BusinessConcepts.BusinessConcept do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias TdBG.Taxonomies.DataDomain
  alias TdBG.BusinessConcepts.BusinessConcept

  @permissions %{
    admin:   [:create, :update, :send_for_approval, :delete, :publish, :reject,
              :deprecate, :see_draft, :see_published],
    publish: [:create, :update, :send_for_approval, :delete, :publish, :reject,
              :deprecate, :see_draft, :see_published],
    create:  [:create, :update, :send_for_approval, :delete, :see_draft,
              :see_published],
    watch:   [:see_published]
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

    timestamps()
  end

  def get_permissions do
    @permissions
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
