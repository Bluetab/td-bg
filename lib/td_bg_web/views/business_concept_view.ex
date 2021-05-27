defmodule TdBgWeb.BusinessConceptView do
  use TdBgWeb, :view
  alias TdBgWeb.DomainView

  def render(
        "show.json",
        %{business_concept: business_concept}
      ) do
    domains = shared_to(business_concept)
    %{data: %{id: business_concept.id, _embedded: %{shared_to: domains}}}
  end

  defp shared_to(%{shared_to: shared_to}) when is_list(shared_to) do
    render_many(shared_to, DomainView, "domain.json")
  end

  defp shared_to(_), do: []
end
