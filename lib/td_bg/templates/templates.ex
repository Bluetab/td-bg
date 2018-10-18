defmodule TdBg.Templates do
  @moduledoc """
  The Templates context.
  """

  import Ecto.Query, warn: false
  alias TdBg.Repo

  alias Ecto.Changeset
  alias TdBg.Taxonomies
  alias TdBg.Taxonomies.Domain

  def get_domain_templates(%Domain{} = domain) do
    get_domain_templates(%{domain_id: domain.id}, [])
  end
  def get_domain_templates(%{domain_id: nil}, templates), do: templates |> Enum.uniq_by(&(&1.id))
  def get_domain_templates(%{domain_id: domain_id}, templates) do
    domain = domain_id
      |> Taxonomies.get_domain!
      |> Repo.preload([:templates])
    templates = templates ++ get_templates_from_domain(domain)
    get_domain_templates(%{domain_id: domain.parent_id}, templates)
  end

  defp get_templates_from_domain(%Domain{} = domain) do
    domain
    |> Map.get(:templates)
  end

  def add_templates_to_domain(%Domain{} = domain, templates) do
    domain
    |> Repo.preload(:templates)
    |> Changeset.change
    |> Changeset.put_assoc(:templates, templates)
    |> Repo.update!
  end

  def count_related_domains(id) do
    count = Repo.one from r in "domains_templates", select: count(r.template_id), where: r.template_id == ^id
    {:count, :domain, count}
  end

end
