Feature: Domains where a user has a given permission create_business_concept
  Authenticated users could list the domains where they have a given permission create_business_concept

  Scenario: List of the domains where the user have a create permission
    Given an existing Domain called "Domain 1"
    And an existing Domain called "Domain 1.1" child of Domain "Domain 1"
    And an existing Domain called "Domain 1.1.1" child of Domain "Domain 1.1"
    And an existing Domain called "Domain 1.1.2" child of Domain "Domain 1.1"
    And an user "pietro.alpin" that belongs to the group "group1"
    And following users exist with the indicated role in Domain "Domain 1"
      | user           | role    |
      | pietro.alpin   | watch   |
    And following users exist with the indicated role in Domain "Domain 1.1.2"
      | user           | role    |
      | pietro.alpin   | publish   |
    And "group1" has a role "publish" in Domain "Domain 1.1"
    When user "pietro.alpin" lists the domains where he has a given permission
    Then the system returns a result with code "Ok"
    And if result "Ok" the retrieved list of domains should not be empty
    And the following domains should be in the list:
      | domain           |
      | Domain 1.1       |
      | Domain 1.1.1     |
      | Domain 1.1.2     |
    And the following domains should not be in the list:
      | domain           |
      | Domain 1         |
