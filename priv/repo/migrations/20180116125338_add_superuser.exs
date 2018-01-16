defmodule TrueBG.Repo.Migrations.AddSuperuser do
  use Ecto.Migration

  alias TrueBG.Accounts
  alias Comeonin.Bcrypt

  @valid_attrs %{password_hash: Bcrypt.hashpwsalt("mypass"),
                 user_name: "app-admin"}

  def change do
    Accounts.create_user(@valid_attrs)
  end
end
