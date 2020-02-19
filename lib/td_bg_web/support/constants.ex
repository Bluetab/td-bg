defmodule TdBg.ErrorConstantsSupport do
  @moduledoc false
  @taxonomy_support_errors [
    uniqueness: [
      name: %{code: "ETD003", name: "existing.domain.name"},
      external_id: %{code: "ETD004", name: "existing.external_id"}
    ],
    integrity_constraint: [
      domain: %{code: "ETD001", name: "existing.domain"},
      business_concept: %{code: "ETD002", name: "existing.business.concept"}
    ]
  ]

  @glossary_support_errors [
    integrity_constraint: [
      business_concept: %{code: "EBG001", name: "concept.error.existing.business.concept"}
    ]
  ]

  def taxonomy_support_errors, do: @taxonomy_support_errors
  def glossary_support_errors, do: @glossary_support_errors
end
