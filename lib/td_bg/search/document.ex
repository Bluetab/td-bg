alias Elasticsearch.Document
alias TdBg.BusinessConcepts
alias TdBg.BusinessConcepts.BusinessConceptVersion
alias TdBg.BusinessConcepts.Indexable
alias TdBg.Repo
alias TdBg.Taxonomies
alias TdCache.TaxonomyCache
alias TdCache.TemplateCache
alias TdCache.UserCache
alias TdDfLib.Format
alias TdDfLib.RichText

defimpl Document, for: BusinessConceptVersion do
  @impl Document
  def id(%BusinessConceptVersion{id: id}), do: id

  @impl Document
  def routing(_), do: false

  @impl Document
  def encode(bcv) do
    %{business_concept: %{domain: domain, type: type}} =
      bcv
      |> Repo.preload(business_concept: :domain)

    %Indexable{business_concept_version: bcv, type: type, domain: domain}
    |> Document.encode()
  end
end

defimpl Document, for: Indexable do
  @impl Document
  def id(%Indexable{business_concept_version: %{id: id}}), do: id

  @impl Document
  def routing(_), do: false

  @impl Document
  def encode(%Indexable{business_concept_version: bcv, type: type, domain: domain}) do
    template = TemplateCache.get_by_name!(type) || %{content: []}
    domain_ids = Taxonomies.get_parent_ids(domain.id)
    domain_parents = Enum.map(domain_ids, &%{id: &1, name: TaxonomyCache.get_name(&1)})
    last_change_by = get_user(bcv.last_change_by)

    content =
      bcv
      |> Map.get(:content)
      |> Format.search_values(template)
      |> confidential()

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
    |> Map.merge(BusinessConcepts.get_concept_counts(bcv.business_concept_id))
    |> Map.put(:content, content)
    |> Map.put(:description, RichText.to_plain_text(bcv.description))
    |> Map.put(:domain, Map.take(domain, [:id, :name]))
    |> Map.put(:domain_ids, domain_ids)
    |> Map.put(:domain_parents, domain_parents)
    |> Map.put(:last_change_by, last_change_by)
    |> Map.put(:template, Map.take(template, [:name, :label]))
  end

  defp get_user(user_id) do
    case UserCache.get(user_id) do
      {:ok, nil} -> %{}
      {:ok, user} -> user
    end
  end

  defp confidential(nil), do: %{}

  defp confidential(content),
    do: update_in(content["_confidential"], &if(&1 == "Si", do: &1, else: "No"))
end
