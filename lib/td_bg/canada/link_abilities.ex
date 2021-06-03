defmodule TdBg.Canada.LinkAbilities do
  @moduledoc """
  Canada permissions model for Business Concept Link resources
  """

  require Logger

  alias TdBg.Auth.Claims
  alias TdBg.BusinessConcepts
  alias TdBg.Canada.TaxonomyAbilities
  alias TdBg.Permissions
  alias TdBg.Taxonomies.Domain
  alias TdCache.Link

  def can?(%Claims{role: "admin"}, :create_concept_link, _resource), do: true
  def can?(%Claims{role: "admin"}, :create_structure_link, _resource), do: true
  def can?(%Claims{role: "admin"}, _action, %Link{}), do: true

  def can?(
        %Claims{} = claims,
        :delete,
        %Link{
          source: "business_concept:" <> business_concept_id
        } = link
      ) do
    case BusinessConcepts.get_business_concept(String.to_integer(business_concept_id)) do
      %{} = concept ->
        delete_link?(claims, link, concept)

      nil ->
        Logger.error(
          "In LinkAbilities.can?/2... concept not found #{inspect(business_concept_id)}"
        )
    end
  end

  def can?(%Claims{} = claims, :create_concept_link, %{domain_id: domain_id}) do
    TaxonomyAbilities.can?(claims, :create_concept_link, %Domain{id: domain_id})
  end

  def can?(%Claims{} = claims, :create_structure_link, %{
        domain_id: domain_id,
        shared_to: shared_to
      }) do
    domain_ids =
      shared_to
      |> Enum.map(& &1.id)
      |> Enum.concat([domain_id])
      |> Enum.uniq()

    Permissions.authorized?(claims, :manage_business_concept_links, domain_ids)
  end

  def can?(%Claims{role: "admin"}, _action, %{hint: :link}), do: true

  def can?(
        %Claims{} = claims,
        :delete,
        %{
          hint: :link,
          resource_type: :data_structure
        } = link
      ) do
    domain_ids = BusinessConcepts.get_domain_ids(link)
    Permissions.authorized?(claims, :manage_business_concept_links, domain_ids)
  end

  def can?(%Claims{} = claims, :delete, %{hint: :link, domain_id: domain_id}) do
    TaxonomyAbilities.can?(claims, :delete_link, %Domain{id: domain_id})
  end

  defp delete_link?(%Claims{} = claims, %Link{target: "data_structure:" <> _}, %{} = concept) do
    domain_ids = BusinessConcepts.get_domain_ids(concept)
    Permissions.authorized?(claims, :manage_business_concept_links, domain_ids)
  end

  defp delete_link?(%Claims{} = claims, _, %{
         domain_id: domain_id
       }) do
    TaxonomyAbilities.can?(claims, :delete_link, %Domain{id: domain_id})
  end
end
