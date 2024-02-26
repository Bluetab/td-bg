defmodule TdBg.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: TdBg.Repo
  use TdDfLib.TemplateFactory

  alias TdBg.BusinessConcepts.BulkUploadEvent
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Comments.Comment
  alias TdBg.Groups.DomainGroup
  alias TdBg.I18nContents.I18nContent
  alias TdBg.UserSearchFilters.UserSearchFilter

  def claims_factory(attrs) do
    %TdBg.Auth.Claims{
      user_id: sequence(:user_id, & &1),
      user_name: sequence("user_name"),
      role: "user",
      jti: sequence("jti")
    }
    |> merge_attributes(attrs)
  end

  def domain_factory do
    %TdBg.Taxonomies.Domain{
      id: System.unique_integer([:positive]),
      name: sequence("domain_name"),
      description: sequence("domain_description"),
      external_id: sequence("domain_external_id")
    }
  end

  def business_concept_factory(attrs) do
    attrs = default_assoc(attrs, :domain_id, :domain)

    %BusinessConcept{
      type: "some_type",
      last_change_by: 1,
      last_change_at: DateTime.utc_now(),
      confidential: false
    }
    |> merge_attributes(attrs)
  end

  def business_concept_version_factory(attrs) do
    {concept_attrs, attrs} = Map.split(attrs, [:type, :domain, :domain_id])
    attrs = default_assoc(attrs, :business_concept_id, :business_concept, concept_attrs)

    %BusinessConceptVersion{
      content: %{},
      business_concept: %{
        type: "some_type",
        last_change_by: 1,
        last_change_at: DateTime.utc_now(),
        confidential: false
      },
      name: sequence("concept_name"),
      last_change_by: 1,
      last_change_at: DateTime.utc_now(),
      status: "draft",
      version: 1,
      in_progress: false
    }
    |> merge_attributes(attrs)
  end

  def comment_factory do
    %Comment{
      resource_type: "business_concept",
      resource_id: sequence(:resource_id, & &1),
      user: build(:comment_user),
      content: sequence("comment_content")
    }
  end

  def comment_user_factory do
    %{
      id: sequence(:user_id, & &1),
      user_name: sequence("user_name"),
      full_name: sequence("full_name")
    }
  end

  def domain_group_factory do
    %DomainGroup{
      name: sequence("group_name")
    }
  end

  def user_search_filter_factory do
    %UserSearchFilter{
      id: sequence(:user_search_filter, & &1),
      name: sequence("filter_name"),
      filters: %{"country" => ["Sp"]},
      user_id: sequence(:user_id, & &1),
      is_global: false
    }
  end

  def shared_concept_factory(attrs) do
    attrs =
      attrs
      |> default_assoc(:domain_id, :domain)
      |> default_assoc(:business_concept_id, :business_concept)

    %TdBg.SharedConcepts.SharedConcept{}
    |> merge_attributes(attrs)
  end

  def hierarchy_factory(attrs) do
    %{
      id: System.unique_integer([:positive]),
      name: sequence("family_"),
      description: sequence("description_"),
      nodes: [],
      updated_at: DateTime.utc_now()
    }
    |> merge_attributes(attrs)
  end

  def node_factory(attrs) do
    name = sequence("node_")
    hierarchy_id = Map.get(attrs, :hierarchy_id, System.unique_integer([:positive]))
    node_id = Map.get(attrs, :node_id, System.unique_integer([:positive]))

    %{
      node_id: node_id,
      hierarchy_id: hierarchy_id,
      parent_id: System.unique_integer([:positive]),
      name: name,
      description: sequence("description_"),
      path: "/#{name}",
      key: "#{hierarchy_id}_#{node_id}"
    }
    |> merge_attributes(attrs)
  end

  def bulk_upload_event_factory(attrs) do
    %BulkUploadEvent{
      file_hash: sequence("filehash"),
      inserted_at: "2022-04-24T11:08:18.215905Z",
      message: sequence("message_"),
      response: %{
        created: [
          System.unique_integer([:positive]),
          System.unique_integer([:positive])
        ],
        updated: [
          System.unique_integer([:positive]),
          System.unique_integer([:positive])
        ],
        errors: []
      },
      status: "COMPLETED",
      task_reference: "0.262460172.3388211201.119663",
      user_id: System.unique_integer([:positive]),
      filename: sequence("filename_")
    }
    |> merge_attributes(attrs)
  end

  def i18n_content_factory(attrs) do
    attrs = default_assoc(attrs, :business_concept_version_id, :business_concept_version)

    %I18nContent{
      name: sequence("i18n_concept_name"),
      lang: "en",
      content: %{"foo" => "bar"}
    }
    |> merge_attributes(attrs)
  end

  defp default_assoc(attrs, id_key, key, build_attrs \\ %{}) do
    if Enum.any?([key, id_key], &Map.has_key?(attrs, &1)) do
      attrs
    else
      Map.put(attrs, key, build(key, build_attrs))
    end
  end
end
