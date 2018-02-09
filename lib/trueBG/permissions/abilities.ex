defimpl Canada.Can, for: TrueBG.Accounts.User do

  #def can?(%TrueBG.Accounts.User{}, _action, nil),  do: false

  # administrator is superpowerful
  def can?(%TrueBG.Accounts.User{is_admin: true}, _action, _domain),  do: true

  # Data domain

  # This is the creation of a business concept in a data domain
  def can?(%TrueBG.Accounts.User{id: user_id}, :create_business_concept, %TrueBG.Taxonomies.DataDomain{id: resource_id})  do
    role = TrueBG.Permissions.get_role_in_resource(%{user_id: user_id, data_domain_id: resource_id})
    role_name = String.to_atom(role.name)
    permissions = TrueBG.Taxonomies.BusinessConcept.get_permissions()
    Enum.member? permissions[role_name], :create
  end

  def can?(%TrueBG.Accounts.User{}, _action, %TrueBG.Taxonomies.DataDomain{}) do  #when action in [:admin, :watch, :create, :publish] do
    true
  end

  def can?(%TrueBG.Accounts.User{}, _action, TrueBG.Taxonomies.DataDomain) do  #when action in [:admin, :watch, :creaBusinte, :publish] do
    true
  end

  def can?(%TrueBG.Accounts.User{}, _action, TrueBG.Taxonomies.BusinessConcept) do  #when action in [:admin, :watch, :creaBusinte, :publish] do
    true
  end

  def can?(%TrueBG.Accounts.User{id: user_id}, action, %TrueBG.Taxonomies.BusinessConcept{} = business_object) when action in [:update, :publish] do
    resource_id = business_object.data_domain_id
    role = TrueBG.Permissions.get_role_in_resource(%{user_id: user_id, data_domain_id: resource_id})
    role_name = String.to_atom(role.name)
    permissions = TrueBG.Taxonomies.BusinessConcept.get_permissions()
    Enum.member? permissions[role_name], action
  end

  def can?(%TrueBG.Accounts.User{}, _action, _domain),  do: false

end
