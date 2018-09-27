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
alias TdBg.BusinessConcepts.BusinessConcept
alias TdBg.BusinessConcepts.BusinessConceptVersion
alias TdBg.Repo
alias Ecto.Changeset

template = Repo.insert!(%Template{
  label: "Empty Tempalte",
  name: "empty",
  is_default: false,
  content: [
  %{
    name: "dominio",
    type: "list",
    label: "Dominio Información de Gestión",
    values: [],
    required: false,
    "form_type": "dropdown",
    description: "Indicar si el término pertenece al dominio de Información de Gestión",
    meta: %{ role: "rolename"}
  }
]

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
  description: %{document: %{object: "block", type: "paragraph", nodes: [%{object: "text", leaves: [%{text: "Description"}]}]}},
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

Repo.insert!(%Template{
  label: "Default Template",
  name: "default_template",
  is_default: true,
  content: [
  %{
    name: "field_1",
    type: "string",
    label: "Field 1",
  },
  %{
    name: "field_2",
    type: "string",
    label: "Field 2",
  },
  %{
    name: "field_3",
    type: "string",
    label: "Field 3",
  },
  %{
    name: "dominio",
    type: "list",
    label: "Dominio Información de Gestión",
    values: [],
    required: false,
    "form_type": "dropdown",
    description: "Indicar si el término pertenece al dominio de Información de Gestión",
    meta: %{ role: "rolename"}
  }
]
})

domain_with_no_template = Repo.insert!(%Domain{
    description: "Domain with no template",
    type: "No template",
    name: "Domain with no template"
})
