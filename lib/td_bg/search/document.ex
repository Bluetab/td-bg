defimpl Elasticsearch.Document, for: TdBg.BusinessConcepts.BusinessConceptVersion do
  alias TdBg.BusinessConcept.RichText
  alias TdBg.BusinessConcepts
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Repo
  alias TdBg.Taxonomies
  alias TdCache.TaxonomyCache
  alias TdCache.TemplateCache
  alias TdCache.UserCache
  alias TdDfLib.Format
  
  def id(business_concept_version), do: business_concept_version.id
  def routing(_), do: false
  def encode(%BusinessConceptVersion{} = bcv) do
    bcv = Repo.preload(bcv, [business_concept: :domain])
    %{
        last_change_by: last_change_by_id,
        business_concept_id: business_concept_id,
        business_concept: business_concept
    } = bcv
    %{type: type, domain_id: domain_id} = business_concept

    template =
      case TemplateCache.get_by_name!(type) do
        nil -> %{content: []}
        template -> template
      end

    domain = Taxonomies.get_raw_domain(domain_id)
    domain_ids = Taxonomies.get_parent_ids(domain_id)

    domain_parents =
      domain_ids
      |> Enum.map(&%{id: &1, name: TaxonomyCache.get_name(&1)})

    last_change_by =
      case UserCache.get(last_change_by_id) do
        {:ok, nil} -> %{}
        {:ok, user} -> user
      end

    counts = BusinessConcepts.get_concept_counts(business_concept_id)
    bcv = Map.merge(bcv, counts)

    content =
      bcv
      |> Map.get(:content)
      |> Format.search_values(template)

    content = confidential(content)

    bcv
    |> Map.take([
      :id,
      :business_concept_id,
      :name,
      :status,
      :version,
      :last_change_at,
      :current,
      :link_count,
      :rule_count,
      :in_progress,
      :inserted_at
    ])
    |> Map.put(:content, content)
    |> Map.put(:description, RichText.to_plain_text(bcv.description))
    |> Map.put(:domain, Map.take(domain, [:id, :name]))
    |> Map.put(:domain_ids, domain_ids)
    |> Map.put(:domain_parents, domain_parents)
    |> Map.put(:last_change_by, last_change_by)
    |> Map.put(:template, Map.take(template, [:name, :label]))
  end

  defp confidential(nil), do: %{}

  defp confidential(content),
    do: update_in(content["_confidential"], &if(&1 == "Si", do: &1, else: "No"))
end