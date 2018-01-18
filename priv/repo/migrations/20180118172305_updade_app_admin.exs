defmodule TrueBG.Repo.Migrations.UpdadeAppAdmin do
  use Ecto.Migration
  alias TrueBG.Accounts

  def change do
    user = Accounts.get_user_by_name("app-admin")
    Accounts.update_user(user, %{user_name: "app-admin", password: "mypass", is_admin: true})
   end
end
