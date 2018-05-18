defmodule TdBgWeb.Hypermedia.HypermediaControllerHelper do
  @moduledoc """
  """

  alias Gettext.Interpolation
  alias TdBgWeb.Router
  alias TdBgWeb.Hypermedia.Link
  alias TdBgWeb.Hypermedia.HypermediaCollection
  alias Guardian.Plug, as: Guardian
  import Canada.Can

  def hypermedia(helper, conn, resource, nested \\ [])
  def hypermedia(helper, conn, resource, nested)  when is_list(resource) do
    %HypermediaCollection{
      collection_hypermedia:
        hypermedia(helper, conn, %{}),
      collection:
        Enum.into(
          Enum.map(
            resource, &({&1, hypermedia(helper, conn, &1, nested)})), %{})
     }
  end
  def hypermedia(helper, conn, resource, [h|t]) do
    hypermedia(helper, conn, resource, t) ++
    [%{h => hypermedia_nested(h, conn, resource)}]
  end
  def hypermedia(helper, conn, resource, []) do
    hypermedia_impl(helper, conn, resource)
  end

  defp hypermedia_impl(helper, conn, resource) do
      current_user = Guardian.current_resource(conn)

      Router.__routes__
      |> Enum.filter(&(!is_nil &1.helper))
      |> Enum.filter(&(String.starts_with?(&1.helper, helper)))
      |> Enum.filter(&(can?(current_user, &1.opts, resource)))
      |> Enum.map(&(interpolate(&1, resource)))
      |> Enum.filter(&(&1.path != nil))
      |> Enum.filter(&(resource == %{} or
        (&1.action != "index" and &1.action != "create")))
  end

  defp interpolate(route, resource) do
    %Link{action: route.opts, path: interpolation(route.path, resource),
     method: route.verb, schema: %{}}
  end

  defp interpolation(path, resource) do
    path = Regex.replace(~r/(:\w*id)/, path, "%{id}")
    case path
      |> Interpolation.to_interpolatable
      |> Interpolation.interpolate(resource) do
        {:ok, route} -> route
        _ -> nil
    end
  end

  defp hypermedia_nested(helper, conn, %{__struct__: _} = resource) do
    hypermedia_nested(helper, conn, struct_to_map(resource))
  end
  defp hypermedia_nested(helper, conn, resource) do
    current_user = Guardian.current_resource(conn)
    Router.__routes__
    |> Enum.filter(&(&1.helper == helper and &1.opts == :index))
    |> Enum.filter(&(can?(current_user, &1.opts, resource)))
    |> Enum.map(&(interpolate(&1, resource)))
    |> Enum.filter(&(&1.path != nil))
  end

  defp struct_to_map(%{__struct__: name} = resource) do
    key = name
    |> Module.split
    |> List.last
    |> String.downcase
    |> Kernel.<>("_id")
    |> String.to_atom
    resource
    |> Map.from_struct()
    |> Map.put(key, resource.id)
  end
end
