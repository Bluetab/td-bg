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

  def can?(%TrueBG.Accounts.User{id: user_id}, :update, %TrueBG.Taxonomies.BusinessConcept{status: status} = business_object) do
    resource_id = business_object.data_domain_id
    role = TrueBG.Permissions.get_role_in_resource(%{user_id: user_id, data_domain_id: resource_id})
    role_name = String.to_atom(role.name)
    permissions = TrueBG.Taxonomies.BusinessConcept.get_permissions()
    Enum.member?(permissions[role_name], :update) &&
      status == Atom.to_string(TrueBG.Taxonomies.BusinessConcept.draft)
  end

  def can?(%TrueBG.Accounts.User{id: user_id}, :send_for_approval, %TrueBG.Taxonomies.BusinessConcept{status: status} = business_object) do
    resource_id = business_object.data_domain_id
    role = TrueBG.Permissions.get_role_in_resource(%{user_id: user_id, data_domain_id: resource_id})
    role_name = String.to_atom(role.name)
    permissions = TrueBG.Taxonomies.BusinessConcept.get_permissions()
    Enum.member?(permissions[role_name], :send_for_approval) &&
      status == Atom.to_string(TrueBG.Taxonomies.BusinessConcept.draft)
  end

  def can?(%TrueBG.Accounts.User{id: user_id}, :reject, %TrueBG.Taxonomies.BusinessConcept{status: status} = business_object) do
    resource_id = business_object.data_domain_id
    role = TrueBG.Permissions.get_role_in_resource(%{user_id: user_id, data_domain_id: resource_id})
    role_name = String.to_atom(role.name)
    permissions = TrueBG.Taxonomies.BusinessConcept.get_permissions()
    Enum.member?(permissions[role_name], :reject) &&
      status == Atom.to_string(TrueBG.Taxonomies.BusinessConcept.pending_approval)
  end

  def can?(%TrueBG.Accounts.User{id: user_id}, :publish, %TrueBG.Taxonomies.BusinessConcept{status: status} = business_object) do
    resource_id = business_object.data_domain_id
    role = TrueBG.Permissions.get_role_in_resource(%{user_id: user_id, data_domain_id: resource_id})
    role_name = String.to_atom(role.name)
    permissions = TrueBG.Taxonomies.BusinessConcept.get_permissions()
    Enum.member?(permissions[role_name], :publish) &&
      status == Atom.to_string(TrueBG.Taxonomies.BusinessConcept.pending_approval)
  end

  def can?(%TrueBG.Accounts.User{}, _action, _domain),  do: false

end
