defmodule TdBg.Canada.LinkAbilities do
  @moduledoc """
  Canada permissions model for Business Concept Link resources
  """

  alias TdBg.Accounts.User
  alias TdBg.BusinessConcepts
  alias TdBg.Canada.TaxonomyAbilities
  alias TdBg.Taxonomies.Domain
  alias TdCache.Link

  require Logger

  def can?(%User{is_admin: true}, _action, %Link{}), do: true

  def can?(%User{} = user, :delete, %Link{source: "business_concept:" <> business_concept_id}) do
    with %{domain_id: domain_id} <-
           BusinessConcepts.get_business_concept!(String.to_integer(business_concept_id)) do
      TaxonomyAbilities.can?(user, :delete_link, %Domain{id: domain_id})
    else
      error ->
        Logger.error("In LinkAbilities.can?/2... #{inspect(error)}")
    end
  end

  def can?(%User{} = user, :create_link, %{domain_id: domain_id}) do
    TaxonomyAbilities.can?(user, :create_link, %Domain{id: domain_id})
  end

  def can?(%User{is_admin: true}, _action, %{hint: :link}), do: true

  def can?(%User{} = user, :delete, %{hint: :link, domain_id: domain_id}) do
    TaxonomyAbilities.can?(user, :delete_link, %Domain{id: domain_id})
  end
end
