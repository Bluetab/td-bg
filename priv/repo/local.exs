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
alias TdBg.Taxonomies.Domain
alias TdBg.BusinessConcepts.BusinessConcept
alias TdBg.BusinessConcepts.BusinessConceptVersion
alias TdBg.Repo
alias TdDf.Templates.Template
alias Ecto.Changeset

reference_template = Repo.insert!(%Template{
  label: "Reference Template",
  name: "reference",
  is_default: false,
  content: [
    %{name: "_confidential",
      group: "Campos especiales",
      label: "Confidencial",
      description: "Indica si el término es connfidencial"
      },
    %{name: "texto",
      type: "string",
      group: "Textos",
      label: "Texto",
      required: false,
      description: "Campo para introducir texto libre"
      },
    %{name: "texto_multiple",
      type: "variable_list",
      group: "Textos",
      label: "Texto múltiple",
      widget: "multiple_input",
      required: false,
      description: "Campo que permite meter una lista de valores libres"
      },
    %{name: "area_texto",
       type: "string",
       group: "Textos",
       label: "Área de texto",
       widget: "textarea",
       required: true,
       description: "Pinta un área de texto para introducir textos de mayor longitud"
       },
    %{name: "lista_dropdown",
      type: "list",
      group: "Listas",
      label: "Lista con desplegable",
      values: ["Elemento1", "Elemento2", "Elemento3", "Elemento4", "Elemento5", "Elemento6", "Elemento7", "Elemento8", "Elemento9", "Elemento10", "Elemento11", "Elemento12"],
      widget: "dropdown",
      required: false,
      description: "Campo con una lista de elementos predefinidos y desplegable donde se puede elegir un valor"
      },
    %{name: "dropdown_multiple",
      type: "variable_list",
      group: "Listas",
      label: "Selección múltiple",
      values: ["Elemento1", "Elemento2", "Elemento3", "Elemento4", "Elemento5", "Elemento6", "Elemento7", "Elemento8", "Elemento9", "Elemento10", "Elemento11", "Elemento12"],
      widget: "dropdown",
      required: false,
      description: "Campo con una lista de elementos predefinidos y desplegable donde se puede elegir un valor"},
    %{name: "lista_radio",
      type: "list",
      group: "Listas",
      label: "Lista con radio button",
      values: ["Si", "No"],
      widget: "radio",
      required: true,
      description: "Campo con una lista de elementos predefinidos que se muestran en pantalla para elegir uno"
      },
    %{name: "texto_dependiente",
      type: "string",
      group: "Listas",
      label: "Campo texto dependiente",
      depends: %{on: "lista_radio", to_be: "Si"},
      required: true,
      description: "Campo que se muestra o no dependiendo del valor de otro campo"
      },
    %{name: "lista_dependiente",
      type: "list",
      group: "Listas",
      label: "Campo lista dependiente",
      values: ["Elemento1", "Elemento2", "Elemento3", "Elemento4", "Elemento5", "Elemento6", "Elemento7", "Elemento8", "Elemento9", "Elemento10", "Elemento11", "Elemento12"],
      widget: "dropdown",
      depends: %{on: "lista_radio", to_be: "Si"},
      required: false,
      description: "Campo que se muestra o no dependiendo del valor de otro campo"
      },
    %{meta: %{role: "Rol de Prueba"},
      name: "role",
      type: "list",
      group: "Listas",
      label: "Usuarios con Rol",
      values: [],
      widget: "dropdown",
      required: false,
      description: "Lista dinámica de usuarios que tienen el rol especificado en la plantilla en el dominio seleccionado al alta del concepto"
      },
    %{name: "urls",
      type: "variable_map_list",
      group: "Otros",
      label: "Urls",
      widget: "pair_list",
      required: false,
      description: "URLs con links"
    }
  ]
})

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

reference_domain = Repo.insert!(%Domain{
    description: "Reference Domain",
    type: "ReferenceDomain",
    name: "Reference Domain"
})

reference_domain
|> Repo.preload(:templates)
|> Changeset.change
|> Changeset.put_assoc(:templates, [reference_template])
|> Repo.update!


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

Repo.insert!(%Domain{
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

Repo.insert!(%Domain{
    description: "Domain with no template",
    type: "No template",
    name: "Domain with no template"
})
