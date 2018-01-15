Feature: User Authentication
  This feature will allow to create and identify users of the application granting them default access
  without any role (or default role)

  Scenario: Creating a New user in the application
    Given an existing user "app-admin" with the "super-admin" role in the application
    And user "app-admin" is logged in the application
    When "app-admin" tries to create a user "New-User"
    Then the system returns a result with code "Created"
    And user "New-user" can be authenticated

  Scenario: Error when creating a new user in the application by a non admin user
    Given an existing user "nobody" without the "super-admin" role in the application
    And user "nobody" is logged in the application
    When "nobody" tries to create a user "New-User"
    Then the system returns a result with code "Forbidden"
    And user "New-user" can not be authenticated

  Scenario: Assigning super-admin role to an existing user
    Given an existing user "app-admin" with the "super-admin" role in the application
    And an existing user "nobody" without the "super-admin" role in the application
    And user "app-admin" is logged in the application
    When "app-admin" tries to assign "super-admin" role to "nobody"
    Then the system returns a result with code "Ok"
    And user "nobody" has "super-admin" role

  Scenario: Error when assigning super-admin role to an existing user
    Given an existing user "nobody" without the "super-admin" role in the application
    And an existing user "John Doe" without the "super-admin" role in the application
    And user "nobody" is logged in the application
    When "nobody" tries to assign "super-admin" role to "John Doe"
    Then the system returns a result with code "Forbidden"
    And user "nobody" has not "super-admin" role
