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
alias TdBg.Templates.Template
alias TdBg.Taxonomies.Domain
alias TdBg.Permissions.Permission
alias TdBg.Permissions.Role
alias TdBg.Permissions.AclEntry
alias TdBg.BusinessConcepts.BusinessConcept
alias TdBg.BusinessConcepts.BusinessConceptVersion
alias TdBg.Repo
alias Ecto.Changeset

Repo.insert!(%Permission{name: Permission.permissions.create_acl_entry})
Repo.insert!(%Permission{name: Permission.permissions.update_acl_entry})
Repo.insert!(%Permission{name: Permission.permissions.delete_acl_entry})

Repo.insert!(%Permission{name: Permission.permissions.create_domain})
Repo.insert!(%Permission{name: Permission.permissions.update_domain})
Repo.insert!(%Permission{name: Permission.permissions.delete_domain})
Repo.insert!(%Permission{name: Permission.permissions.view_domain})

Repo.insert!(%Permission{name: Permission.permissions.create_business_concept})
Repo.insert!(%Permission{name: Permission.permissions.update_business_concept})
Repo.insert!(%Permission{name: Permission.permissions.send_business_concept_for_approval})
Repo.insert!(%Permission{name: Permission.permissions.delete_business_concept})
Repo.insert!(%Permission{name: Permission.permissions.publish_business_concept})
Repo.insert!(%Permission{name: Permission.permissions.reject_business_concept})
Repo.insert!(%Permission{name: Permission.permissions.deprecate_business_concept})
Repo.insert!(%Permission{name: Permission.permissions.manage_business_concept_alias})
Repo.insert!(%Permission{name: Permission.permissions.view_draft_business_concepts})
Repo.insert!(%Permission{name: Permission.permissions.view_approval_pending_business_concepts})
Repo.insert!(%Permission{name: Permission.permissions.view_published_business_concepts})
Repo.insert!(%Permission{name: Permission.permissions.view_versioned_business_concepts})
Repo.insert!(%Permission{name: Permission.permissions.view_rejected_business_concepts})
Repo.insert!(%Permission{name: Permission.permissions.view_deprecated_business_concepts})

template = Repo.insert!(%Template{
  name: "empty",
  content: [
  %{
    name: "dominio",
    type: "list",
    label: "Dominio Información de Gestión",
    values: [
      "Cliente existente/Previsión de la demanda",
      "Cliente existente/Atención Cliente",
      "Cliente existente/Ciclo de Ingresos",
      "Cliente existente/Producto",
    ],
    required: false,
    "form_type": "dropdown",
    description: "Indicar si el término pertenece al dominio de Información de Gestión",
    meta: %{ role: "rolename"}
  }
]

})

rolename = Repo.insert!(%Role{
    name: "rolename"
})

domain1 = Repo.insert!(%Domain{
    description: "Dominio 1",
    type: "Especial",
    name: "Dominio1"
})

domain2 = Repo.insert!(%Domain{
    description: "Dominio 2",
    type: "Especial",
    name: "Dominio2",
    parent_id: domain1.id
})

domain2
|> Repo.preload(:templates)
|> Changeset.change
|> Changeset.put_assoc(:templates, [template])
|> Repo.update!

business_concept = Repo.insert!(%BusinessConcept{
  domain_id: domain2.id,
  type: "empty",
  last_change_by: 1234,
  last_change_at: DateTime.utc_now()
  })

Repo.insert!(%BusinessConceptVersion{
  content: %{},
  related_to: [],
  description: "Descripción",
  last_change_at: DateTime.utc_now(),
  mod_comments: "Mod comments",
  last_change_by: 1234,
  name: "Nombre",
  reject_reason: "Rechazo",
  status: BusinessConcept.status.draft,
  current: true,
  version: 1,
  business_concept_id: business_concept.id
  })

domain3 = Repo.insert!(%Domain{
    description: "Dominio 3",
    type: "Especial",
    name: "Dominio3",
    parent_id: domain2.id
})


Repo.insert!(%AclEntry{
  principal_id: 3,
  principal_type: "user",
  resource_id: domain3.id,
  resource_type: "domain",
  role_id: rolename.id
})

Repo.insert!(%AclEntry{
  principal_id: 4,
  principal_type: "user",
  resource_id: domain3.id,
  resource_type: "domain",
  role_id: rolename.id
})

Repo.insert!(%AclEntry{
  principal_id: 1,
  principal_type: "group",
  resource_id: domain1.id,
  resource_type: "domain",
  role_id: rolename.id
})
