Feature: Roles Admin
  Authenticated users will have a default "watch" role for all Domains
  - App-admin will have "admin" role in all Domains
  - An admin in a Domain can grant watch, create, publish or admin role in that Domain or its children to any users
  - A user with a role in a Domain  has that role as default also for all its children
  - The existing roles in order of level of permissions are admin, publish, create, watch

  # Background:
  #   Given an existing Domain called "My Parent Domain"
  #   And an existing Domain called "My Child Domain" as child of Domain "My Parent Domain"
  #   And an existing Domain called "My Domain" as child of Domain "My Child Domain"

  # TODO: These tests need refactoring
  
  #  Scenario Outline: Granting roles to parent Domain
  #    Given an existing Domain called "My Parent Domain"
  #    And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
  #    And an existing Domain called "My Domain" child of Domain "My Child Domain"
  #    When "app-admin" grants <role> role to user "johndoe" in Domain <group>
  #    Then the system returns a result with code "Created"
  #    And the user "johndoe" has <parent_domain_role> role in Domain "My Parent Domain"
  #    And the user "johndoe" has <child_domain_role> role in Domain "My Child Domain"
  #    And the user "johndoe" has <domain_role> role in Domain "My Domain"
  #
  #    Examples:
  #      | role    | group             | parent_domain_role  | child_domain_role | domain_role |
  #      | admin   | My Parent Domain  | admin               | admin             | admin       |
  #      | admin   | My Child Domain   | none                | admin             | admin       |
  #      | publish | My Parent Domain  | publish             | publish           | publish     |
  #      | publish | My Child Domain   | none                | publish           | publish     |
  #      | create  | My Parent Domain  | create              | create            | create      |
  #      | create  | My Child Domain   | none                | create            | create      |
  #
  #  Scenario Outline: Granting roles to leaf Domain
  #    Given an existing Domain called "My Parent Domain"
  #    And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
  #    And an existing Domain called "My Domain" child of Domain "My Child Domain"
  #    When "app-admin" grants <role> role to user "johndoe" in Domain "My Domain"
  #    Then the system returns a result with code "Created"
  #    And the user "johndoe" has <parent_domain_role> role in Domain "My Parent Domain"
  #    And the user "johndoe" has <child_domain_role> role in Domain "My Child Domain"
  #    And the user "johndoe" has <domain_role> role in Domain "My Domain"
  #
  #    Examples:
  #      | role    | parent_domain_role  | child_domain_role | domain_role |
  #      | admin   | none                | none              | admin       |
  #      | publish | none                | none              | publish     |
  #      | create  | none                | none              | create      |
  #