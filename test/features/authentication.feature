Feature: User Authentication
  This feature will allow to create and identify users of the application granting them default access
  without any permission

  Scenario: logging
    When user "app-admin" tries to log into the application with password "mypass"
    Then the system returns a token with code "Created"

  Scenario: logging error
    When user "app-admin" tries to log into the application with password "inventedpass"
    Then the system returns a result with code "Forbidden"

  Scenario: logging error for non existing user
    When user "nobody" tries to log into the application with password "inventedpass"
    Then the system returns a result with code "Forbidden"

  Scenario: Creating a New user in the application
    Given user "app-admin" is logged in the application with password "mypass"
    When "app-admin" tries to create a user "newuser" with password "new-password"
    Then the system returns a result with code "Created"
    And user "newuser" can be authenticated with password "new-password"

  Scenario: Error when creating a new user in the application by a non admin user
    Given an existing user "nobody" with password "inventedpass" without "super-admin" permission
    And user "nobody" is logged in the application with password "inventedpass"
    When "nobody" tries to create a user "newuser" with password "newpass"
    Then the system returns a result with code "Forbidden"
    And user "newuser" can not be authenticated with password "newpass"

  # Scenario: Assigning super-admin permission to an existing user
  #   Given an existing user "nobody" with password "mypass" without "super-admin" permission
  #   And user "app-admin" is logged in the application
  #   When "app-admin" tries to assign "super-admin" permission to "nobody"
  #   Then the system returns a result with code "Ok"
  #   And user "nobody" can be authenticated with password "mypass" with "super-admin" permission
  #
  # Scenario: Error when assigning super-admin permission to an existing user
  #   Given an existing user "nobody" with password "mypass" with "super-admin" permission
  #   And an existing user "John Doe" with password "mypass" without "super-admin" permission
  #   And user "nobody" is logged in the application
  #   When "nobody" tries to assign "super-admin" permission to "John Doe"
  #   Then the system returns a result with code "Forbidden"
  #   And user "John Doe" can be authenticated with password "mypass" without "super-admin" permission
  #
  # Scenario: Error when creating a duplicated user
  #   Given an existing user "uniqueuser" with password "mypass" with "super-admin" permission
  #   And user "app-admin" is logged in the application
  #   When "app-admin" tries to create a user "uniqueuser" with password "new-password"
  #   Then the system returns a result with code "Forbidden"
  #   And user "uniqueuser" can not be authenticated with password "new-password"
  #   And user "uniqueuser" can be authenticated with password "mypass"
  #
  # Scenario: Password modification
  #   Given an existing user "johndoe" with password "secret" without "super-admin" permission
  #   And user "johndoe" is logged in the application
  #   When "johndoe" tries to modify his password with following data:
  #     | old_password | new_password |
  #     | secret       | newsecret    |
  #   Then the system returns a result with code "Ok"
  #   And user "johndoe" can not be authenticated with password "secret"
  #   And user "johndoe" can be authenticated with password "newsecret"
  #
  # Scenario: Password modification error
  #   Given an existing user "johndoe" with password "secret" without "super-admin" permission
  #   And user "johndoe" is logged in the application
  #   When "johndoe" tries to modify his password with following data:
  #     | old_password | new_password |
  #     | dontknow     | newsecret    |
  #   Then the system returns a result with code "Ok"
  #   And user "johndoe" can not be authenticated with password "dontknow"
  #   And user "johndoe" can be authenticated with password "secret"
  #
  # Scenario: Loggout
    Given an existing user "johndoe" with password "secret" without "super-admin" permission
    And user "johndoe" is logged in the application with password "secret"
    When "johndoe" signs out of the application
    Then the system returns a result with code "Ok"
    And user "johndoe" gets a "Forbidden" code when he pings the application
  #
  # Scenario: Loggout for a user that is not logged
  #   Given an existing user "johndoe" with password "secret" without "super-admin" permission
  #   When "johndoe" signs out of the application
  #   Then the system returns a result with code "Forbidden"
  #   And user "johndoe" gets a "Forbidden" code when he pings the application
