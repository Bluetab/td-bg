defmodule TdBg.Permissions do
  @moduledoc """
  The Permissions context.
  """

  alias TdBg.Auth.Claims

  @defaults [
    "manage_business_concept_links",
    "manage_confidential_business_concepts",
    "view_approval_pending_business_concepts",
    "view_deprecated_business_concepts",
    "view_draft_business_concepts",
    "view_published_business_concepts",
    "view_rejected_business_concepts",
    "view_versioned_business_concepts"
  ]

  def get_default_permissions, do: @defaults

  def has_permission?(%Claims{jti: jti}, permission) do
    TdCache.Permissions.has_permission?(jti, permission)
  end

  def has_any_permission?(%Claims{jti: jti}, permissions) do
    Enum.any?(permissions, &TdCache.Permissions.has_permission?(jti, &1))
  end

  def authorized?(claims, permission, resource_ids \\ :any, resource_type \\ "domain")

  def authorized?(%{jti: jti}, permission, :any, resource_type) do
    TdCache.Permissions.has_permission?(jti, permission, resource_type)
  end

  def authorized?(%{jti: jti}, permission, resource_ids, resource_type) do
    TdCache.Permissions.has_permission?(jti, permission, resource_type, resource_ids)
  end
end
