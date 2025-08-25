defmodule TdBgWeb.DomainController do
  use TdBgWeb, :controller
  use TdHypermedia, :controller

  import Canada, only: [can?: 2]

  alias TdBg.Taxonomies
  alias TdBg.Taxonomies.Domain

  action_fallback(TdBgWeb.FallbackController)

  def index(conn, params) do
    claims = conn.assigns[:current_resource]
    domains = Taxonomies.list_domains(%{}, preload: [:domain_group])

    case get_actions(params) do
      [] ->
        domains = Enum.filter(domains, &can?(claims, show(&1)))

        render(conn, "index.json",
          domains: domains,
          hypermedia: hypermedia("domain", conn, domains)
        )

      actions ->
        filtered_domains = filter_domains(claims, domains, actions, params)
        render(conn, "index.json", domains: filtered_domains)
    end
  end

  defp filter_domains(claims, domains, actions, %{"filter" => "all"}) do
    Enum.filter(domains, &can_all?(actions, claims, &1))
  end

  defp filter_domains(claims, domains, actions, _params) do
    Enum.filter(domains, &can_any?(actions, claims, &1))
  end

  defp can_all?(actions, claims, domain) do
    alias Canada.Can

    actions
    |> Enum.map(&String.to_atom/1)
    |> Enum.all?(&Can.can?(claims, &1, domain))
  end

  defp can_any?(actions, claims, domain) do
    alias Canada.Can

    actions
    |> Enum.map(&String.to_atom/1)
    |> Enum.any?(&Can.can?(claims, &1, domain))
  end

  defp get_actions(params) do
    params
    |> Map.get("actions", "")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  def create(conn, %{"domain" => domain_params}) do
    claims = conn.assigns[:current_resource]

    with %Domain{} = domain <- Taxonomies.apply_changes(Domain, domain_params),
         {:can, true} <- {:can, can_create_domain(claims, domain)},
         {:ok, %Domain{} = domain} <- Taxonomies.create_domain(domain_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.domain_path(conn, :show, domain))
      |> render("show.json", domain: domain)
    end
  end

  defp can_create_domain(claims, %{parent_id: parent_id}) when not is_nil(parent_id) do
    case Taxonomies.get_domain(parent_id) do
      {:ok, parent_domain} ->
        can?(claims, create(parent_domain))

      {:error, :not_found} ->
        true
    end
  end

  defp can_create_domain(claims, domain) do
    can?(claims, create(domain))
  end

  def show(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]

    with domain <- Taxonomies.get_domain!(id, [:parent, :domain_group]),
         {:can, true} <- {:can, can?(claims, show(domain))} do
      render(conn, "show.json",
        domain: enrich_group(domain),
        hypermedia: hypermedia("domain", conn, domain)
      )
    end
  end

  def parentable_ids(conn, %{"domain_id" => id}) do
    claims = conn.assigns[:current_resource]

    with domain <- Taxonomies.get_domain!(id, [:parent, :domain_group]),
         {:can, true} <- {:can, can?(claims, show(domain))},
         parentable_ids <- Taxonomies.get_parentable_ids(claims, domain) do
      render(conn, "parentable_ids.json", parentable_ids: parentable_ids)
    end
  end

  def update(conn, %{"id" => id, "domain" => domain_params}) do
    claims = conn.assigns[:current_resource]

    with {:ok, domain} <- Taxonomies.get_domain(id),
         {:can, true} <- {:can, can_update?(claims, domain, domain_params)},
         {:ok, %Domain{} = updated_domain} <- Taxonomies.update_domain(domain, domain_params) do
      render(conn, "show.json", domain: updated_domain)
    end
  end

  defp can_update?(claims, %{parent_id: id} = domain, %{parent_id: id} = _new_domain) do
    can?(claims, update(domain))
  end

  defp can_update?(claims, %{parent_id: _} = domain, %{parent_id: _} = new_domain) do
    # Changing parent_id requires delete/update permission on existing domain
    # and create permission on new domain
    Enum.all?([
      can?(claims, move(domain)),
      can?(claims, create(new_domain))
    ])
  end

  defp can_update?(claims, %Domain{} = domain, %{} = params) do
    new_domain = Taxonomies.apply_changes(domain, params)
    can_update?(claims, domain, new_domain)
  end

  def delete(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]

    with {:ok, domain} <- Taxonomies.get_domain(id),
         {:can, true} <- {:can, can?(claims, delete(domain))},
         {:ok, %Domain{}} <- Taxonomies.delete_domain(domain) do
      send_resp(conn, :no_content, "")
    end
  end

  def count_bc_in_domain_for_user(conn, %{"domain_id" => id, "user_name" => user_name}) do
    claims = conn.assigns[:current_resource]

    with {:ok, domain} <- Taxonomies.get_domain(id),
         {:can, true} <- {:can, can?(claims, show(domain))},
         {domain_id, ""} <- Integer.parse(id) do
      counter = Taxonomies.count_existing_users_with_roles(domain_id, user_name)
      render(conn, "domain_bc_count.json", counter: counter)
    end
  end

  defp enrich_group(%Domain{domain_group: nil} = domain), do: domain

  defp enrich_group(
         %Domain{domain_group: %{id: id}, parent: %{domain_group_id: domain_group_id}} = domain
       )
       when domain_group_id != id do
    with_group_status(domain)
  end

  defp enrich_group(%Domain{domain_group: %{}, parent: nil} = domain) do
    with_group_status(domain)
  end

  defp enrich_group(domain), do: domain

  defp with_group_status(domain) do
    domain_group =
      domain
      |> Map.get(:domain_group)
      |> Map.put(:status, :root)

    Map.put(domain, :domain_group, domain_group)
  end
end
