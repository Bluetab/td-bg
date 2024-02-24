defmodule TdBg.I18nContents.I18nContents do
  @moduledoc """
  The I18n Contents context.
  """

  import Ecto.Query

  alias TdBg.I18nContents.I18nContent
  alias TdBg.Repo

  def get_by_i18n_content!(params, opts \\ []) do
    I18nContent
    |> Repo.get_by!(params)
    |> Repo.preload(opts[:preload] || [])
  end

  def get_all_i18n_content_by_bcv_id(id) do
    I18nContent
    |> where([ic], ic.business_concept_version_id == ^id)
    |> Repo.all()
  end

  def create_i18n_content(params) do
    params
    |> I18nContent.changeset()
    |> Repo.insert()
  end

  def update_i18n_content(%I18nContent{} = i18n_content, params) do
    i18n_content
    |> I18nContent.changeset(params)
    |> Repo.update()
  end
end
