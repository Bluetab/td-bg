defmodule TdBg.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: TdBg.Repo
  alias TdBg.BusinessConcepts.BusinessConcept
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.BusinessConcepts.BusinessConceptAlias

  def user_factory do
    %TdBg.Accounts.User {
      id: 0,
      user_name: "bufoncillo",
      is_admin: false
    }
  end

  def domain_group_factory do
    %TdBg.Taxonomies.DomainGroup {
      name: "My domain group",
      description: "My domain group description",
    }
  end

  def data_domain_factory do
    %TdBg.Taxonomies.DataDomain {
      name: "My data domain",
      description: "My data domain description",
      domain_group: build(:domain_group)
    }
  end

  def business_concept_factory do
    %BusinessConcept {
      data_domain: build(:data_domain),
      type: "some type",
      last_change_by: 1,
      last_change_at: DateTime.utc_now(),
    }
  end

  def business_concept_version_factory do
    %BusinessConceptVersion {
      business_concept: build(:business_concept),
      content: %{},
      name: "My business term",
      description: "My business term description",
      last_change_by: 1,
      last_change_at: DateTime.utc_now(),
      status: BusinessConcept.status.draft,
      version: 1,
    }
  end

  def business_concept_alias_factory do
    %BusinessConceptAlias {
      business_concept_id: 0,
      name: "my great alias",
    }
  end

  def role_factory do
    %TdBg.Permissions.Role {
      name: "watch"
    }
  end

  def acl_entry_domain_group_user_factory do
    %TdBg.Permissions.AclEntry {
      principal_id: nil,
      principal_type: "user",
      resource_id: nil,
      resource_type: "domain_group",
      role: nil
    }
  end

  def acl_entry_data_domain_user_factory do
    %TdBg.Permissions.AclEntry {
      principal_id: nil,
      principal_type: "user",
      resource_id: nil,
      resource_type: "data_domain",
      role: nil
    }
  end
end
