defmodule TdBg.Canada.LinkAbilities do
  @moduledoc """
  Canada permissions model for Business Concept Link resources
  """

  alias TdBg.Auth.Claims
  alias TdBg.BusinessConcepts
  alias TdBg.Canada.TaxonomyAbilities
  alias TdBg.Taxonomies.Domain
  alias TdCache.Link

  require Logger

  def can?(%Claims{is_admin: true}, :create_link, _resource), do: true

  def can?(%Claims{is_admin: true}, _action, %Link{}), do: true

  def can?(%Claims{} = claims, :delete, %Link{
        source: "business_concept:" <> business_concept_id
      }) do
    case BusinessConcepts.get_business_concept!(String.to_integer(business_concept_id)) do
      %{domain_id: domain_id} ->
        TaxonomyAbilities.can?(claims, :delete_link, %Domain{id: domain_id})

      error ->
        Logger.error("In LinkAbilities.can?/2... #{inspect(error)}")
    end
  end

  def can?(%Claims{} = claims, :create_link, %{domain_id: domain_id}) do
    TaxonomyAbilities.can?(claims, :create_link, %Domain{id: domain_id})
  end

  def can?(%Claims{is_admin: true}, _action, %{hint: :link}), do: true

  def can?(%Claims{} = claims, :delete, %{hint: :link, domain_id: domain_id}) do
    TaxonomyAbilities.can?(claims, :delete_link, %Domain{id: domain_id})
  end
end
