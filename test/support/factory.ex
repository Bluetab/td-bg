defmodule TrueBG.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: TrueBG.Repo
  alias TrueBG.Taxonomies.BusinessConcept

  def user_factory do
    %TrueBG.Accounts.User {
      user_name: "bufoncillo",
      password: "bufoncillo",
    }
  end

  def domain_group_factory do
    %TrueBG.Taxonomies.DomainGroup {
      name: "My domain group",
      description: "My domain group description",
    }
  end

  def data_domain_factory do
    %TrueBG.Taxonomies.DataDomain {
      name: "My data domain",
      description: "My data domain description",
      domain_group: build(:domain_group)
    }
  end

  def business_concept_factory do
    %BusinessConcept {
      content: %{},
      type: "Businness Term",
      name: "My business term",
      description: "My business term description",
      modifier: 1,
      last_change: DateTime.utc_now(),
      data_domain: build(:data_domain),
      status: Atom.to_string(BusinessConcept.draft),
      version: 1,
    }
  end

  def role_factory do
    %TrueBG.Permissions.Role {
      name: "watch"
    }
  end

  def acl_entry_domain_group_user_factory do
    %TrueBG.Permissions.AclEntry {
      principal_id: nil,
      principal_type: "user",
      resource_id: nil,
      resource_type: "domain_group",
      role: nil
    }
  end

end
