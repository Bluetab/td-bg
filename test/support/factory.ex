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

  def domain_factory do
    %TdBg.Taxonomies.Domain {
      name: "My domain",
      description: "My domain description",
    }
  end

  def child_domain_factory do
    %TdBg.Taxonomies.Domain {
      name: "My child domain",
      description: "My child domain description",
      parent: build(:domain)
    }
  end

  def business_concept_factory do
    %BusinessConcept {
      domain: build(:domain),
      type: "some type",
      last_change_by: 1,
      last_change_at: DateTime.utc_now(),
      aliases: []
    }
  end

  def business_concept_version_factory do
    %BusinessConceptVersion {
      business_concept: build(:business_concept),
      content: %{},
      related_to: [],
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

  def permission_factory do
    %TdBg.Permissions.Permission {
      name: "custom_permission"
    }
  end

  def role_factory do
    %TdBg.Permissions.Role {
      name: "custom_role",
      permissions: []
    }
  end

  def acl_entry_domain_user_factory do
    %TdBg.Permissions.AclEntry {
      principal_id: nil,
      principal_type: "user",
      resource_id: nil,
      resource_type: "domain",
      role: nil
    }
  end

end
