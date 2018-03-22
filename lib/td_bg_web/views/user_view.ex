defmodule TdBgWeb.UserView do
  use TdBgWeb, :view
  alias TdBgWeb.UserView

  def render("index.json", %{users: users}) do
    %{data: render_many(users, UserView, "user.json")}
  end

  def render("show.json", %{user: user}) do
    %{data: render_one(user, UserView, "user.json")}
  end

  def render("user.json", %{user: user}) do
    %{id: user.id,
      user_name: user.user_name,
      is_admin: user.is_admin,
      email: user.email,
      full_name: user.full_name
    }
  end
end
