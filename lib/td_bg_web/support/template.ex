defmodule TdBgWeb.TemplateSupport do
  @moduledoc false

  alias TdBg.Accounts.User
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.Repo
  alias TdBg.Taxonomies.Domain
  alias TdBg.Templates

  @td_auth_api Application.get_env(:td_bg, :auth_service)[:api_service]

  def preprocess_templates(templates, ctx \\ %{}) do
    process_template_meta([], templates, ctx)
  end

  defp process_template_meta(acc, [], _context), do: acc
  defp process_template_meta(acc, [head|tail], %{user_roles: _} = ctx) do
    acc
    |> process_template_meta(head, ctx)
    |> process_template_meta(tail, ctx)
  end
  defp process_template_meta(acc, [head|tail], %{domain: domain} = ctx) do
    user_roles = @td_auth_api.get_domain_user_roles(domain.id)
    ctx = ctx |> Map.put(:user_roles, user_roles)
    process_template_meta(acc, [head|tail], ctx)
  end
  defp process_template_meta(acc, template, ctx) do
    content = process_meta([], template.content, ctx)
    processed = Map.put(template, :content, content)
    [processed|acc]
  end

  defp process_meta(acc, [], _ctx), do: acc
  defp process_meta(acc, [head|tail], ctx) do
    acc
    |> process_meta(head, ctx)
    |> process_meta(tail, ctx)
  end
  defp process_meta(acc, %{"type" => type, "meta" => meta} = field, ctx) do
    field = case {type, meta} do
      {"list", %{"role" => role_name}} ->
        user = Map.get(ctx, :user, nil)
        domain = Map.get(ctx, :domain, nil)
        user_roles = Map.get(ctx, :user_roles, [])
        process_role_meta(field, user, role_name, domain, user_roles)
      _ -> field
    end
    field_without_meta = Map.delete(field, "meta")
    acc ++ [field_without_meta]
  end
  defp process_meta(acc, %{} = field, _ctx) do
    acc ++ [field]
  end

  # TODO: Refactor (roles and ACL entries are now in td_auth)
  defp process_role_meta(%{} = field, %User{} = user, role_name, %Domain{} = domain, user_roles)
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
  defp process_role_meta(field, _user, _role, _domain, _user_roles), do: field

  # TODO: unit test this
  def get_preprocessed_template(%BusinessConceptVersion{} = version, %User{} = user) do
    domain = version.business_concept
    |> Repo.preload(:domain)
    |> Map.get(:domain)

    template = version.business_concept.type
    |> Templates.get_template_by_name

    process_template_meta([], [template], %{domain: domain, user: user})
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
