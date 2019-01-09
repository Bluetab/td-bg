defmodule TdBgWeb.BusinessConceptSupport do
  @moduledoc false
  require Logger
  use TdBgWeb, :controller
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.ErrorConstantsSupport
  alias TdBg.Repo
  alias TdBg.Taxonomies
  alias TdBg.Taxonomies.Domain
  alias TdBgWeb.ErrorView

  import Canada, only: [can?: 2]

  @errors ErrorConstantsSupport.glossary_support_errors()

  def handle_bc_errors(conn, error) do
    case error do
      false ->
        conn
        |> put_status(:forbidden)
        |> render(ErrorView, :"403.json")

      {:name_not_available} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: [@errors.existing_concept]})

      {:not_valid_related_to} ->
        # TODO: change this error to standard format
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: %{related_to: ["invalid"]}})

      {:error, %Ecto.Changeset{data: %{__struct__: _}} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(TdBgWeb.ChangesetView, "error.json",
          changeset: changeset,
          prefix: "concept.error"
        )

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(TdBgWeb.ChangesetView, "error.json",
          changeset: changeset,
          prefix: "concept.content.error"
        )

      error ->
        Logger.error("Business concept... #{inspect(error)}")

        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
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
    concept
    |> Repo.preload(business_concept: [:domain])
    |> Map.get(:business_concept)
    |> Map.get(:domain)
    |> get_parent_ous(user)
    |> Enum.uniq()
  end
end
