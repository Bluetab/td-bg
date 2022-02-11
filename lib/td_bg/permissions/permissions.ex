defmodule TdBg.Permissions do
  @moduledoc """
  The Permissions context.
  """

  alias TdBg.Auth.Claims

  @defaults %{
    "manage_business_concept_links" => :none,
    "manage_confidential_business_concepts" => :none,
    "view_approval_pending_business_concepts" => :none,
    "view_deprecated_business_concepts" => :none,
    "view_draft_business_concepts" => :none,
    "view_published_business_concepts" => :none,
    "view_rejected_business_concepts" => :none,
    "view_versioned_business_concepts" => :none
  }

  def get_search_permissions(%Claims{role: role}) when role in ["admin", "service"] do
    Map.new(@defaults, fn {p, _} -> {p, :all} end)
  end

  def get_search_permissions(%Claims{jti: jti}) do
    session_permissions = TdCache.Permissions.get_session_permissions(jti)
    default_permissions = get_default_permissions()

    session_permissions
    |> Map.take(Map.keys(@defaults))
    |> Map.merge(default_permissions, fn
      _, _, :all -> :all
      _, scope, _ -> scope
    end)
  end

  defp get_default_permissions do
    case TdCache.Permissions.get_default_permissions() do
      {:ok, permissions} -> Enum.reduce(permissions, @defaults, &Map.replace(&2, &1, :all))
      _ -> @defaults
    end
  end

  def has_permission?(%Claims{jti: jti}, permission) do
    TdCache.Permissions.has_permission?(jti, permission)
  end

  def has_any_permission?(%Claims{jti: jti}, permissions) do
    Enum.any?(permissions, &TdCache.Permissions.has_permission?(jti, &1))
  end

  @doc """
  Check if the authenticated user has a permission in a domain.

  ## Examples

      iex> authorized?(%Claims{}, "create", 12)
      false

  """
  def authorized?(%Claims{jti: jti}, permission, domain_id) do
    TdCache.Permissions.has_permission?(jti, permission, "domain", domain_id)
  end
end
