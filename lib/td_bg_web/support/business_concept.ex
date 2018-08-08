defmodule TdBgWeb.BusinessConceptSupport do
  @moduledoc false
  require Logger
  use TdBgWeb, :controller
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Repo
  alias TdBg.Taxonomies
  alias TdBg.Taxonomies.Domain
  alias TdBgWeb.ErrorView

  import Canada, only: [can?: 2]

  def handle_bc_errors(conn, error) do
    case error do
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")
      {:name_not_available} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{"errors": %{name: ["unique"]}})
      {:not_valid_related_to} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{"errors": %{related_to: ["invalid"]}})
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(TdBgWeb.ChangesetView, "error.json", changeset: changeset)
      error ->
        Logger.error("Business concept... #{inspect(error)}")
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

  # TODO: Should we retrieve the domains children too ??
  defp get_children_ous([], _user), do: []
  defp get_children_ous([head|tail], user) do
    get_children_ous(head, user) ++ get_children_ous(tail, user)
  end
  defp get_children_ous(%Domain{} = domain, user) do
    child_domains = Taxonomies.get_children_domains(domain)
    child_ous = get_children_ous(child_domains, user)
    case can?(user, show(domain)) do
      true -> [domain.name|child_ous]
      false -> child_ous
    end
  end

  defp get_parent_ous(%Domain{parent_id: nil} = domain, user) do
    case can?(user, show(domain)) do
      true -> [domain.name]
      false -> []
    end
  end

  defp get_parent_ous(%Domain{parent_id: parent_id} = domain, user) do
    parent_domain = Taxonomies.get_domain!(parent_id)
    case can?(user, show(domain)) do
      true -> [domain.name] ++ get_parent_ous(parent_domain, user)
      false -> []
    end
  end

  def get_concept_ous(%BusinessConceptVersion{} = concept, user) do
    domain =
      concept
        |> Repo.preload(business_concept: [:domain])
        |> Map.get(:business_concept)
        |> Map.get(:domain)

    Enum.uniq(get_parent_ous(domain, user) ++ get_children_ous(domain, user))
  end

end
