defmodule TdBg.ErrorConstantsSupport do
  @moduledoc false
  @taxonomy_support_errors %{
    existing_child_domain: %{code: "ETD001", name: "error.existing.domain"},
    existing_child_business_concept: %{code: "ETD002", name: "error.existing.business.concept"}
  }

  @glossary_support_errors %{
    existing_concept: %{code: "EBG001", name: "concept.error.existing.business.concept"}
  }

  def taxonomy_support_errors, do: @taxonomy_support_errors
  def glossary_support_errors, do: @glossary_support_errors

end
