defmodule TdBg.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: TdBg.Repo

  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Comments.Comment
  alias TdBg.Groups.DomainGroup
  alias TdBg.UserSearchFilters.UserSearchFilter

  def claims_factory(attrs) do
    %TdBg.Auth.Claims{
      user_id: sequence(:user_id, & &1),
      user_name: sequence("user_name"),
      role: "user",
      jti: sequence("jti"),
      is_admin: Map.get(attrs, :role) == "admin"
    }
    |> merge_attributes(attrs)
  end

  def domain_factory do
    %TdBg.Taxonomies.Domain{
      name: sequence("domain_name"),
      description: sequence("domain_description"),
      external_id: sequence("domain_external_id")
    }
  end

  def business_concept_factory do
    %BusinessConcept{
      domain: build(:domain),
      type: "some_type",
      last_change_by: 1,
      last_change_at: DateTime.utc_now(),
      confidential: false
    }
  end

  def business_concept_version_factory(attrs) do
    attrs = default_assoc(attrs, :business_concept_id, :business_concept)

    %BusinessConceptVersion{
      content: %{},
      name: "My business term",
      description: %{"document" => "My business term description"},
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
      filters: %{country: ["Sp"]},
      user_id: sequence(:user_id, & &1)
    }
  end

  defp default_assoc(attrs, id_key, key) do
    if Enum.any?([key, id_key], &Map.has_key?(attrs, &1)) do
      attrs
    else
      Map.put(attrs, key, build(key))
    end
  end
end
