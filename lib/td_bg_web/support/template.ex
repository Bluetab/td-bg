defmodule TdBgWeb.TemplateSupport do
  @moduledoc false

  alias TdBg.Accounts.User
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Repo
  alias TdBg.Taxonomies.Domain
  alias TdBg.Templates

  @td_auth_api Application.get_env(:td_bg, :auth_service)[:api_service]

  def preprocess_templates(templates, ctx \\ %{})
  def preprocess_templates(templates, %{domain: domain} = ctx) do
    user_roles = @td_auth_api.get_domain_user_roles(domain.id)
    ctx = Map.put(ctx, :user_roles, user_roles)
    change_templates([], templates, ctx)
  end
  def preprocess_templates(templates, ctx) do
    change_templates([], templates, ctx)
  end

  defp change_templates(acc, [head|tail], ctx) do
    acc
    |> change_template(head, ctx)
    |> change_templates(tail, ctx)
  end
  defp change_templates(acc, [], _context), do: acc

  defp change_template(acc, template, ctx) do
    content = change_fields([], template.content, ctx)
    processed = Map.put(template, :content, content)
    [processed|acc]
  end

  defp change_fields(acc, [head|tail], ctx) do
    acc
    |> change_field(head, ctx)
    |> change_fields(tail, ctx)
  end
  defp change_fields(acc, [], _ctx), do: acc

  defp change_field(acc, %{"name" => "_confidential"} = field, _ctx) do
    redefined_field = field
    |> Map.put("type", "list")
    |> Map.put("widget", "radio")
    |> Map.put("required", true)
    |> Map.put("default", "No")
    |> Map.drop(["meta"])
    acc ++ [redefined_field]
  end
  defp change_field(acc, %{"type" => type, "meta" => meta} = field, ctx) do
    field = case {type, meta} do
      {"list", %{"role" => role_name}} ->
        user = Map.get(ctx, :user, nil)
        domain = Map.get(ctx, :domain, nil)
        user_roles = Map.get(ctx, :user_roles, [])
        apply_role_meta(field, user, role_name, domain, user_roles)
      _ -> field
    end
    field_without_meta = Map.delete(field, "meta")
    acc ++ [field_without_meta]
  end
  defp change_field(acc, %{} = field, _ctx),  do: acc ++ [field]

  # TODO: Refactor (roles and ACL entries are now in td_auth)
  defp apply_role_meta(%{} = field, %User{} = user, role_name, %Domain{} = domain, user_roles)
    when not is_nil(user) and
         not is_nil(role_name) and
         not is_nil(domain) do
    users_by_role = user_roles
      |> Enum.find(&(&1.role_name == role_name))
    users = case users_by_role do
      %{users: u} -> u
      nil -> []
    end
    usernames = users
      |> Enum.map(&(&1.full_name))
    field = Map.put(field, "values", usernames)
    case Enum.find(users, &(&1.id == user.id)) do
      nil -> field
      u -> Map.put(field, "default", u.full_name)
    end
  end
  defp apply_role_meta(field, _user, _role, _domain, _user_roles), do: field

  # TODO: unit test this
  def get_preprocessed_template(%BusinessConceptVersion{} = version, %User{} = user) do
    domain = version.business_concept
    |> Repo.preload(:domain)
    |> Map.get(:domain)

    template = version.business_concept.type
    |> Templates.get_template_by_name

    change_templates([], [template], %{domain: domain, user: user})
    |> Enum.at(0)
  end

  # TODO: unit test this
  def get_template(%BusinessConceptVersion{} = version) do
    version
    |> Map.get(:business_concept)
    |> Map.get(:type)
    |> Templates.get_template_by_name
  end

end
