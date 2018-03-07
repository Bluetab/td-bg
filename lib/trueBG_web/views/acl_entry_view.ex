defmodule TdBGWeb.AclEntryView do
  use TdBGWeb, :view
  alias TdBGWeb.AclEntryView

  def render("index.json", %{acl_entries: acl_entries}) do
    %{data: render_many(acl_entries, AclEntryView, "acl_entry.json")}
  end

  def render("show.json", %{acl_entry: acl_entry}) do
    %{data: render_one(acl_entry, AclEntryView, "acl_entry.json")}
  end

  def render("acl_entry.json", %{acl_entry: acl_entry}) do
    %{id: acl_entry.id,
      principal_type: acl_entry.principal_type,
      principal_id: acl_entry.principal_id,
      resource_type: acl_entry.resource_type,
      resource_id: acl_entry.resource_id,
      role_id: acl_entry.role_id
    }
  end
end
