defmodule TdBgWeb.ErrorConstantsSupport do
  @moduledoc false
  @taxonomy_support_errors %{
    existing_child_domain: %{code: "ETD001", name: "domain.error.existing.domain"},
    existing_child_business_concept: %{code: "ETD002", name: "domain.error.existing.business.concept"}
  }

  def taxonomy_support_errors, do: @taxonomy_support_errors

end
