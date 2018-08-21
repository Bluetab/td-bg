defmodule TdBgWeb.ApiServices.HttpGrafanaService do
  @moduledoc false

  alias Poison, as: JSON
  alias Grafana.Dashboard
  alias TdBg.BusinessConcepts
  alias TdBg.Templates

  def create_panels(id) do
    case Dashboard.get("bc_"<> to_string(id)) do
      {:ok, _dashboard} ->
        Dashboard.delete("bc_"<> to_string(id))
        Dashboard.new(build_dashboard(id))
      {:error, _resp} ->
        Dashboard.new(build_dashboard(id))
    end
  end

  def delete_panel(id) do
    Dashboard.delete("bc_"<> to_string(id))
  end

  defp build_dashboard(id) do
    dashboard = File.read!(Path.join([priv_dir(:td_bg), grafana_json()]))
    dashboard = Regex.replace(~r/id=\\\"XXX\\\"/, dashboard, "id=\\\"#{id}\\\"")
    dashboard = Regex.replace(~r/\"title_bc\"/, dashboard, "\"bc_#{id}\"")
    dashboard = Regex.replace(~r/\"id_panel\"/, dashboard, "#{id*10}")
    template_name =
      Templates.get_template_by_name(BusinessConcepts.get_business_concept_version!(id).business_concept.type).name
    dashboard = Regex.replace(~r/template_name/, dashboard, "#{template_name}")
    dashboard = Regex.replace(~r/datasource_name/, dashboard, "#{datasource()}")
    dashboard |> JSON.decode!
  end

  def get_dashboard(id) do
    Dashboard.get("bc_"<> to_string(id))
  end

  defp datasource, do: Application.get_env(:grafana, :datasource)

  defp grafana_json, do: Application.get_env(:grafana, :grafana_json)

  def priv_dir(app), do: "#{:code.priv_dir(app)}"

end
