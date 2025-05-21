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
  alias TdCluster.Cluster.TdAi.Indices

  def can?(%Claims{role: "admin"}, :download_links), do: true

  def can?(%Claims{} = claims, :download_links) do
    Permissions.has_permission?(claims, :manage_business_concept_links)
  end

  def can?(%Claims{role: "admin"}, :create_concept_link, _resource), do: true
  def can?(%Claims{role: "admin"}, :create_structure_link, _resource), do: true

  def can?(%Claims{role: "admin"}, :suggest_structure_link, _resource) do
    case Indices.exists_enabled?() do
      {:ok, enabled?} -> enabled?
      _ -> false
    end
  end

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

  def can?(%Claims{} = claims, :create_structure_link, %{} = concept) do
    domain_ids = BusinessConcepts.get_domain_ids(concept)
    Permissions.authorized?(claims, :manage_business_concept_links, domain_ids)
  end

  def can?(%Claims{} = claims, :suggest_structure_link, %{} = concept) do
    domain_ids = BusinessConcepts.get_domain_ids(concept)
    {:ok, enabled?} = Indices.exists_enabled?()

    Permissions.authorized?(claims, :manage_business_concept_links, domain_ids) && enabled?
  end

  def can?(%Claims{} = claims, :create_implementation, %{} = concept) do
    domain_ids = BusinessConcepts.get_domain_ids(concept)

    Permissions.authorized?(claims, :manage_ruleless_implementations, domain_ids) &&
      Permissions.authorized?(claims, :manage_quality_rule_implementations, domain_ids)
  end

  def can?(%Claims{} = claims, :create_raw_implementation, %{} = concept) do
    domain_ids = BusinessConcepts.get_domain_ids(concept)

    Permissions.authorized?(claims, :manage_raw_quality_rule_implementations, domain_ids) &&
      Permissions.authorized?(claims, :manage_ruleless_implementations, domain_ids)
  end

  def can?(%Claims{} = claims, :create_link_implementation, %{} = concept) do
    domain_ids = BusinessConcepts.get_domain_ids(concept)
    Permissions.authorized?(claims, :link_implementation_business_concept, domain_ids)
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

  def can?(%Claims{} = claims, :delete, %{
        hint: :link,
        resource_type: :implementation,
        domain_id: domain_id
      }) do
    Permissions.authorized?(claims, :link_implementation_business_concept, domain_id)
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
