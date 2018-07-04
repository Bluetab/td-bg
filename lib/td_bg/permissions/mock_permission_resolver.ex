defmodule TdBg.Permissions.MockPermissionResolver do
  @moduledoc """
  A mock permissions resolver defining the default permissions for the admin, watch, create and publish
  roles
  """
  use Agent

  alias Poision

  @role_permissions %{
    "admin" => [
      "create_acl_entry", "update_acl_entry", "delete_acl_entry", "create_domain", "update_domain",
      "delete_domain", "view_domain", "create_business_concept", "update_business_concept",
      "send_business_concept_for_approval", "delete_business_concept", "publish_business_concept",
      "reject_business_concept", "deprecate_business_concept", "manage_business_concept_alias",
      "view_draft_business_concepts", "view_approval_pending_business_concepts", "view_published_business_concepts",
      "view_versioned_business_concepts", "view_rejected_business_concepts", "view_deprecated_business_concepts"
    ],
    "publish" => [
        "view_domain", "create_business_concept", "update_business_concept", "send_business_concept_for_approval",
        "delete_business_concept", "publish_business_concept","reject_business_concept","deprecate_business_concept",
        "manage_business_concept_alias", "view_draft_business_concepts", "view_approval_pending_business_concepts",
        "view_published_business_concepts", "view_versioned_business_concepts", "view_rejected_business_concepts",
        "view_deprecated_business_concepts"],
    "watch" => [
        "view_domain", "view_published_business_concepts", "view_versioned_business_concepts", "view_deprecated_business_concepts",
        "view_draft_business_concepts", "view_rejected_business_concepts"
    ],
    "create" => [
        "view_domain", "create_business_concept", "update_business_concept", "send_business_concept_for_approval",
        "delete_business_concept", "view_draft_business_concepts", "view_published_business_concepts",
        "view_versioned_business_concepts", "view_approval_pending_business_concepts", "view_deprecated_business_concepts"
    ]
  }
    
  def start_link(_) do
    Agent.start_link(fn -> [] end, name: :MockPermissions)
    Agent.start_link(fn -> Map.new end, name: :MockSessions)
  end

  def has_permission?(session_id, permission, resource_type, resource_id) do
    user_id = Agent.get(:MockSessions, &Map.get(&1, session_id))
    Agent.get(:MockPermissions, &(&1))
      |> Enum.filter(&(&1.principal_id == user_id && &1.resource_type == resource_type && &1.resource_id == resource_id))
      |> Enum.any?(&can?(&1.role_name, permission))
  end

  defp can?("admin", _permission), do: true
  defp can?(role, permission) do
    case Map.get(@role_permissions, role) do
      nil -> false
      permissions -> Enum.member?(permissions, permission)
    end
  end

  def create_acl_entry(item) do
    Agent.update(:MockPermissions, &([item|&1]))
  end

  def register_token(resource) do
    %{"sub" => sub, "jti" => jti} = resource |> Map.take(["sub", "jti"])
    %{"id" => user_id} = sub |> Poison.decode!
    Agent.update(:MockSessions, &Map.put(&1, jti, user_id))
  end

  def get_acls_by_resource_type(session_id, resource_type) do
    user_id = Agent.get(:MockSessions, &Map.get(&1, session_id))
    Agent.get(:MockPermissions, &(&1))
      |> Enum.filter(&(&1.principal_id == user_id && &1.resource_type == resource_type))
      |> Enum.map(fn %{role_name: role_name} = map -> Map.put(map, :permissions, Map.get(@role_permissions, role_name)) end)
      |> Enum.map(&(Map.take(&1, [:resource_type, :resource_id, :permissions, :role_name])))
  end
end