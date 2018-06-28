Feature: User Groups Roles
  Management users groups roles

  # TODO: These tests need to be
#  Scenario Outline: Granting roles to parent Domain
#    Given an existing Domain called "My Parent Domain"
#    And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
#    And an existing Domain called "My Domain" child of Domain "My Child Domain"
#    And an user "johndoe" that belongs to the group "group1"
#    When "app-admin" grants <role> role to group "group1" in Domain <domain>
#    Then the system returns a result with code "Created"
#    And the user "johndoe" has <parent_domain_role> role in Domain "My Parent Domain"
#    And the user "johndoe" has <child_domain_role> role in Domain "My Child Domain"
#    And the user "johndoe" has <domain_role> role in Domain "My Domain"
#
#    Examples:
#      | role    | domain            | parent_domain_role  | child_domain_role | domain_role |
#      | admin   | My Parent Domain  | admin               | admin             | admin       |
#      # | admin   | My Child Domain   | none                | admin             | admin       |
#      # | publish | My Parent Domain  | publish             | publish           | publish     |
#      # | publish | My Child Domain   | none                | publish           | publish     |
#      # | create  | My Parent Domain  | create              | create            | create      |
#      # | create  | My Child Domain   | none                | create            | create      |
