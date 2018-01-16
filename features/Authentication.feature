Feature: User Authentication
  This feature will allow to create and identify users of the application granting them default access
  without any permission 

  Scenario: logging
    Given an existing user "app-admin" with password "mypass" with "super-admin" permission
    When user "app-admin" tries to log into the application with password "mypass"
    Then the system returns a token with code "Created"

  Scenario: logging error
    Given an existing user "app-admin" with password "mypass" with "super-admin" permission
    When user "app-admin" tries to log into the application with password "inventedpass"
    Then returns a result with code "Forbidden"

  Scenario: logging error for non existing user
    When user "nobody" tries to log into the application with password "inventedpass"
    Then returns a result with code "Forbidden"

  Scenario: Creating a New user in the application
    Given an existing user "app-admin" with password "mypass" with "super-admin" permission
    And user "app-admin" is logged in the application
    When "app-admin" tries to create a user "newuser" with password "new-password"
    Then the system returns a result with code "Created"
    And user "newuser" can be authenticated with password "new-password"

  Scenario: Error when creating a new user in the application by a non admin user
    Given an existing user "nobody" with password "mypass" without "super-admin" permission
    And user "nobody" is logged in the application
    When "nobody" tries to create a user "newuser" with password "newpass"
    Then the system returns a result with code "Forbidden"
    And user "newuser" can not be authenticated with password "newpass"

  Scenario: Assigning super-admin permission to an existing user
    Given an existing user "app-admin" with password "mypass" with "super-admin" permission
    And an existing user "nobody" with password "mypass" without "super-admin" perission
    And user "app-admin" is logged in the application
    When "app-admin" tries to assign "super-admin" permission to "nobody"
    Then the system returns a result with code "Ok"
    And user "nobody" can be authenticated with password "mypass" with "super-admin" permission

  Scenario: Error when assigning super-admin permission to an existing user
    Given an existing user "nobody" with password "mypass" with "super-admin" permission
    And an existing user "John Doe" with password "mypass" without "super-admin" permission
    And user "nobody" is logged in the application
    When "nobody" tries to assign "super-admin" permission to "John Doe"
    Then the system returns a result with code "Forbidden"
    And user "John Doe" can be authenticated with password "mypass" without "super-admin" permission
