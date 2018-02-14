defmodule TrueBG.BusinessConcepts.BusinessConcept do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias TrueBG.Taxonomies.DataDomain
  alias TrueBG.BusinessConcepts.BusinessConcept

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
            versioned: "versioned"}

  schema "business_concepts" do
    field :content, :map
    field :type, :string
    field :name, :string
    field :description, :string
    field :modifier, :integer
    field :last_change, :utc_datetime
    belongs_to :data_domain, DataDomain
    field :status, :string
    field :reject_reason, :string
    field :mod_comments, :string
    belongs_to :last_version, BusinessConcept
    field :version, :integer

    timestamps()
  end

  def get_permissions do
    @permissions
  end

  def status do
    @status
  end

  @doc false
  def create_changeset(%BusinessConcept{} = business_concept, attrs) do
    business_concept
    |> cast(attrs, [:content, :type, :name, :description, :modifier,
                    :last_change, :data_domain_id, :version,
                    :mod_comments])
    |> validate_required([:content, :type, :name, :modifier, :last_change,
                          :data_domain_id, :version])
    |> validate_length(:name, max: 255)
    |> validate_length(:description,  max: 500)
    |> validate_length(:mod_comments, max: 500)
    |> put_change(:status, Atom.to_string(:draft))
    |> unique_constraint(:business_concept,
                                    name: :index_business_concept_by_version_name_type)
  end

  def update_changeset(%BusinessConcept{} = business_concept, attrs) do
    business_concept
    |> cast(attrs, [:content, :name, :description, :modifier, :last_change,
                    :data_domain_id])
    |> validate_required([:content, :name, :modifier, :last_change,
                          :data_domain_id])
    |> validate_length(:name, max: 255)
    |> validate_length(:description, max: 500)
    |> unique_constraint(:business_concept,
                                    name: :index_business_concept_by_version_name_type)
  end

  @doc false
  def update_status_changeset(%BusinessConcept{} = business_concept, attrs) do
    business_concept
    |> cast(attrs, [:status])
    |> validate_required([:status])
    |> validate_inclusion(:status, Map.values(BusinessConcept.status))
  end

  def reject_changeset(%BusinessConcept{} = business_concept, attrs) do
    business_concept
    |> cast(attrs, [:reject_reason])
    |> validate_length(:reject_reason, max: 500)
    |> put_change(:status, BusinessConcept.status.rejected)
  end

end
