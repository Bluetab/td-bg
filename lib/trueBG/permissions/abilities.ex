defimpl Canada.Can, for: TrueBG.Accounts.User do

  def can?(%TrueBG.Accounts.User{is_admin: _is_admin}, _action, nil) do
    false
  end

  def can?(%TrueBG.Accounts.User{is_admin: _is_admin}, _action, _data_domain = %TrueBG.Taxonomies.DataDomain{}) do  #when action in [:admin, :watch, :create, :publish] do
    true
  end

  def can?(%TrueBG.Accounts.User{is_admin: _is_admin}, _action, TrueBG.Taxonomies.DataDomain) do  #when action in [:admin, :watch, :create, :publish] do
    true
  end

end