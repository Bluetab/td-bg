defmodule TdBg.Repo.Migrations.DomainNamesToExternalIds do
  use Ecto.Migration

  import Ecto.Query

  alias TdBg.Repo

  def change do
    from(d in "domains")
    |> where([d], is_nil(d.external_id))
    |> select([d], %{id: d.id, name: d.name})
    |> Repo.all()
    |> Enum.map(&update_domain/1)
  end

  defp update_domain(%{id: id, name: name}) do
    now = DateTime.utc_now()

    from(d in "domains")
    |> where([d], d.id == ^id)
    |> update(set: [external_id: ^name, updated_at: ^now])
    |> Repo.update_all([])
  end
end
