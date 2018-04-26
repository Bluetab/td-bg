defmodule TdBg.Permissions.Permission do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias TdBg.Permissions.Permission
  alias TdBg.Permissions.Role

  @permissions %{create_acl_entry: "create_acl_entry",
                 # update_acl_entry: "update_acl_entry",
                 # delete_acl_entry: "delete_acl_entry",
                 create_domain: "create_domain",
                 update_domain: "update_domain",
                 delete_domain: "delete_domain",
                 create_business_concept: "create_business_concept",
                 update_business_concept: "update_business_concept",
                 send_business_concept_for_approval: "send_business_concept_for_approval",
                 delete_business_concept: "delete_business_concept",
                 publish_business_concept: "publish_business_concept",
                 reject_business_concept: "reject_business_concept",
                 deprecate_business_concept: "deprecate_business_concept",
                 manage_business_concept_alias: "manage_business_concept_alias",
                 view_draft_business_concepts: "view_draft_business_concepts",
                 view_approval_pending_business_concepts: "view_approval_pending_business_concepts",
                 view_published_business_concepts: "view_published_business_concepts",
                 view_versioned_business_concepts: "view_versioned_business_concepts",
                 view_rejected_business_concepts: "view_rejected_business_concepts",
                 view_deprecated_business_concepts: "view_deprecated_business_concepts"
               }

  schema "permissions" do
    field :name, :string
    many_to_many :roles, Role, join_through: "roles_permissions"

    timestamps()
  end

  def permissions do
    @permissions
  end

  @doc false
  def changeset(%Permission{} = permission, attrs) do
    permission
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

end
