# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     TdBg.Repo.insert!(%TdBg.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias TdBg.Permissions.Permission
alias TdBg.Permissions.Role
alias TdBg.Repo
alias Ecto.Changeset

get_role = fn(name) ->
    case Repo.get_by(Role, [name: name]) do
      nil -> Repo.insert!(%Role{name: name})
      other -> other
    end
end

get_permission = fn(name) ->
  case Repo.get_by(Permission, name: name) do
    nil -> Repo.insert!(%Permission{name: name})
    permission -> permission
  end
end

add_permissions_to_role = fn(permissions, role) ->
  role
  |> Repo.preload(:permissions)
  |> Changeset.change
  |> Changeset.put_assoc(:permissions, permissions)
  |> Repo.update!
end

admin   = get_role.("admin")
watch   = get_role.("watch")
create  = get_role.("create")
publish = get_role.("publish")

create_acl_entry = Permission.permissions.create_acl_entry |> get_permission.()
update_acl_entry = Permission.permissions.update_acl_entry |> get_permission.()
delete_acl_entry = Permission.permissions.delete_acl_entry |> get_permission.()

create_domain = Permission.permissions.create_domain |> get_permission.()
update_domain = Permission.permissions.update_domain |> get_permission.()
delete_domain = Permission.permissions.delete_domain |> get_permission.()

create_business_concept = Permission.permissions.create_business_concept |> get_permission.()
update_business_concept = Permission.permissions.update_business_concept |> get_permission.()
send_business_concept_for_approval = Permission.permissions.send_business_concept_for_approval |> get_permission.()
delete_business_concept = Permission.permissions.delete_business_concept |> get_permission.()
publish_business_concept = Permission.permissions.publish_business_concept |> get_permission.()
reject_business_concept = Permission.permissions.reject_business_concept |> get_permission.()
deprecate_business_concept = Permission.permissions.deprecate_business_concept |> get_permission.()
manage_business_concept_alias = Permission.permissions.manage_business_concept_alias |> get_permission.()
view_draft_business_concepts = Permission.permissions.view_draft_business_concepts |> get_permission.()
view_approval_pending_business_concepts = Permission.permissions.view_approval_pending_business_concepts |> get_permission.()
view_published_business_concepts = Permission.permissions.view_published_business_concepts |> get_permission.()
view_versioned_business_concepts = Permission.permissions.view_versioned_business_concepts |> get_permission.()
view_rejected_business_concepts = Permission.permissions.view_rejected_business_concepts |> get_permission.()
view_deprecated_business_concepts = Permission.permissions.view_deprecated_business_concepts |> get_permission.()

admin_permissions = [create_acl_entry,
                     update_acl_entry,
                     delete_acl_entry,
                     create_domain,
                     update_domain,
                     delete_domain,
                     create_business_concept,
                     update_business_concept,
                     send_business_concept_for_approval,
                     delete_business_concept,
                     publish_business_concept,
                     reject_business_concept,
                     deprecate_business_concept,
                     manage_business_concept_alias,
                     view_draft_business_concepts,
                     view_approval_pending_business_concepts,
                     view_published_business_concepts,
                     view_versioned_business_concepts,
                     view_rejected_business_concepts,
                     view_deprecated_business_concepts
                   ]

watch_permissions = [view_published_business_concepts,
                     view_versioned_business_concepts,
                     view_deprecated_business_concepts
                    ]

create_permissions = [create_business_concept,
                      update_business_concept,
                      send_business_concept_for_approval,
                      delete_business_concept,
                      view_published_business_concepts,
                      view_versioned_business_concepts,
                      view_deprecated_business_concepts
                    ]

publish_permissions = [create_business_concept,
                       update_business_concept,
                       send_business_concept_for_approval,
                       delete_business_concept,
                       publish_business_concept,
                       reject_business_concept,
                       deprecate_business_concept,
                       manage_business_concept_alias,
                       view_draft_business_concepts,
                       view_approval_pending_business_concepts,
                       view_published_business_concepts,
                       view_versioned_business_concepts,
                       view_rejected_business_concepts,
                       view_deprecated_business_concepts
                     ]

add_permissions_to_role.(admin_permissions, admin)
add_permissions_to_role.(watch_permissions, watch)
add_permissions_to_role.(create_permissions, create)
add_permissions_to_role.(publish_permissions, publish)
