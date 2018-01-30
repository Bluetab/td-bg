Feature: Roles Admin
  Authenticated users will have a default "watch" role for all Domain Groups and Data domains
  - App-admin will have "admin" role in all Domain Groups and Data domains
  - An admin in a Domain Group or Data Domain can grant watch, create, publish or admin role in that Group/Domain or its children to any users
  - A user with a role in a Domain Group or Data Domain has that role as default for also for all its children
  - The existing roles in order of level of permissions are admin, publish, create, watch

  # Background:
  #   Given an existing Domain Group called "My Parent Group"
  #   And an existing Domain Group called "My Child Group" as child of Domain Group "My Parent Group"
  #   And an existing Data Domain called "My Domain" as child of Domain Group "My Child Group"

  Scenario Outline: Granting roles to domain group
    Given an existing Domain Group called "My Parent Group"
    And an existing Domain Group called "My Child Group" child of Domain Group "My Parent Group"
    And an existing Data Domain called "My Domain" child of Domain Group "My Child Group"
    And an existing user "johndoe" with password "secret" without "super-admin" permission
    And user "app-admin" is logged in the application
    When "app-admin" grants <role> role to user "johndoe" in Domain Group <group>
    Then the system returns a result with code "Created"
    And the user "johndoe" has <parent_group_role> role in Domain Group "My Parent Group"
    And the user "johndoe" has <child_group_role> role in Domain Group "My Child Group"
    And the user "johndoe" has <domain_role> role in Data Domain "My Domain"

    Examples:
      | role    | group             | parent_group_role  | child_group_role | domain_role |
      | admin   | My Parent Group   | admin              | admin            | admin       |
      | admin   | My Child Group    | watch              | admin            | admin       |
      | publish | My Parent Group   | publish            | publish          | publish     |
      | publish | My Child Group    | watch              | publish          | publish     |
      | create  | My Parent Group   | create             | create           | create      |
      | create  | My Child Group    | watch              | create           | create      |

  Scenario Outline: Granting roles to data domain
    Given an existing Domain Group called "My Parent Group"
    And an existing Domain Group called "My Child Group" child of Domain Group "My Parent Group"
    And an existing Data Domain called "My Domain" child of Domain Group "My Child Group"
    And an existing user "johndoe" with password "secret" without "super-admin" permission
    And user "app-admin" is logged in the application
    When "app-admin" grants <role> role to user "johndoe" in Data Domain "My Domain"
    Then the system returns a result with code "Created"
    And the user "johndoe" has <parent_group_role> role in Domain Group "My Parent Group"
    And the user "johndoe" has <child_group_role> role in Domain Group "My Child Group"
    And the user "johndoe" has <domain_role> role in Data Domain "My Domain"

    Examples:
      | role    | parent_group_role  | child_group_role | domain_role |
      | admin   | watch              | watch            | admin       |
      | publish | watch              | watch            | publish     |
      | create  | watch              | watch            | create      |

#  Scenario Outline: Granting roles by non admin user to domain group
#    Given an existing user "johndoe" with password "pas2w0rd" without "super-admin" permission
#    And an existing user "hariseldon" with password "fundaci0n" without "super-admin" permission
#    And user "johndoe" is logged in the application
#    When "johndoe" grants <role> role to user "hariseldon" in Domain Group <group>
#    Then the system returns a result with code "Forbidden"
#    And the user "hariseldon" has "watch" role in Domain Group "Risks"
#    And the user "hariseldon" has "watch" role in Domain Group "Markets"
#    And the user "hariseldon" has "watch" role in Data Domain "Credit Risks"
#
#    Examples:
#      | role    | group   |
#      | admin   | Risks   |
#      | admin   | Markets |
#      | publish | Risks   |
#      | publish | Markets |
#      | create  | Risks   |
#      | create  | Markets |
#
#  Scenario Outline: Granting roles by non admin user to data domain
#    Given an existing user "johndoe" with password "pas2w0rd" without "super-admin" permission
#    And an existing user "hariseldon" with password "fundaci0n" without "super-admin" permission
#    And user "johndoe" is logged in the application
#    When "johndoe" grants <role> role to user "hariseldon" in Data Domain "Credit Risks"
#    Then the system returns a result with code "Forbidden"
#    And the user "hariseldon" has <parent_group_role> role in Domain Group "Risks"
#    And the user "hariseldon" has <child_group_role> role in Domain Group "Markets"
#    And the user "hariseldon" has <domain_role> role in Data Domain "Credit Risks"
#
#    Examples:
#      | role    | parent_group_role  | child_group_role | domain_role |
#      | admin   | watch              | watch            | watch       |
#      | publish | watch              | watch            | watch       |
#      | create  | watch              | watch            | watch       |
