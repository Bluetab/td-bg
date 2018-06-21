Feature: Roles Admin
  Authenticated users will have a default "watcher" role for all Domains and Domains
  - App-admin will have "admin" role in all Domains and Domains
  - An admin in a Domain or Domain can grant watch, create, publish or admin role in that Group/Domain or its children to any users
  - A user with a role in a Domain or Domain has that role as default for also for all its children
  - The existing roles in order of level of permissions are admin, publish, create, watch

  Scenario Outline: Granting roles to Domain by group manager
    Given an existing Domain called "My Parent Domain"
    And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
    And following users exist with the indicated role in Domain "My Parent Domain"
      | user      | role    |
      | watcher   | watch   |
      | creator   | create  |
      | publisher | publish |
      | admin     | admin   |
    When "<user>" grants <role> role to user "johndoe" in Domain "My Parent Domain"
    Then the system returns a result with code "<code>"
    And if result "<code>" is "Created", the user "johndoe" has "<group_role>" role in Domain "My Parent Domain"
    And if result "<code>" is "Created", the user "johndoe" has "<domain_role>" role in Domain "My Child Domain"

    Examples:
      | user       | role      | code         | group_role  | domain_role |
      | watcher    | admin     | Unauthorized | -           | -           |
      | creator    | admin     | Unauthorized | -           | -           |
      | publisher  | admin     | Unauthorized | -           | -           |
      | admin      | admin     | Created      | admin       | admin       |
      | watcher    | publish   | Unauthorized | -           | -           |
      | creator    | publish   | Unauthorized | -           | -           |
      | publisher  | publish   | Unauthorized | -           | -           |
      | admin      | publish   | Created      | publish     | publish     |
      | watcher    | create    | Unauthorized | -           | -           |
      | creator    | create    | Unauthorized | -           | -           |
      | publisher  | create    | Unauthorized | -           | -           |
      | admin      | create    | Created      | create      | create      |


  Scenario Outline: Granting roles to Domain by domain manager
    Given an existing Domain called "My Parent Domain"
    And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
    And following users exist with the indicated role in Domain "My Child Domain"
      | user      | role    |
      | watcher   | watch   |
      | creator   | create  |
      | publisher | publish |
      | admin     | admin   |
    When "<user>" grants <role> role to user "johndoe" in Domain "My Child Domain"
    Then the system returns a result with code "<code>"
    And if result "<code>" is "Created", the user "johndoe" has "<domain_role>" role in Domain "My Child Domain"

    Examples:
      | user       | role      | code         | domain_role |
      | watcher    | admin     | Unauthorized | -           |
      | creator    | admin     | Unauthorized | -           |
      | publisher  | admin     | Unauthorized | -           |
      | admin      | admin     | Created      | admin       |
      | watcher    | publish   | Unauthorized | -           |
      | creator    | publish   | Unauthorized | -           |
      | publisher  | publish   | Unauthorized | -           |
      | admin      | publish   | Created      | publish     |
      | watcher    | create    | Unauthorized | -           |
      | creator    | create    | Unauthorized | -           |
      | publisher  | create    | Unauthorized | -           |
      | admin      | create    | Created      | create      |

   Scenario: List of user with custom permission in a Domain
     Given an existing Domain called "My Parent Domain"
     And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
     And following users exist with the indicated role in Domain "My Child Domain"
       | user           | role    |
       | pietro.alpin   | watch   |
       | Hari.seldon    | create  |
       | tomclancy      | create  |
       | publisher      | publish |
       | Peter.sellers  | create  |
       | tom.sawyer     | admin   |
     When "app-admin" lists all users with custom permissions in Domain "My Child Domain"
     Then the system returns a result with following data:
       | user           | role    |
       | tom.sawyer     | admin   |
       | publisher      | publish |
       | Hari.seldon    | create  |
       | tomclancy      | create  |
       | Peter.sellers  | create  |
       | pietro.alpin   | watch   |

   Scenario: List of user with custom permission in a Domain
     Given an existing Domain called "My Parent Domain"
     And following users exist with the indicated role in Domain "My Parent Domain"
       | user           | role    |
       | pietro.alpin   | watch   |
       | Hari.seldon    | create  |
       | tomclancy      | create  |
       | publisher      | publish |
       | Peter.sellers  | create  |
       | tom.sawyer     | admin   |
     When "app-admin" lists all users with custom permissions in Domain "My Parent Domain"
     Then the system returns a result with following data:
       | user           | role    |
       | tom.sawyer     | admin   |
       | publisher      | publish |
       | Hari.seldon    | create  |
       | tomclancy      | create  |
       | Peter.sellers  | create  |
       | pietro.alpin   | watch   |


   Scenario: List of users available for setting custom permission in a Domain
     Given an existing Domain called "My Parent Domain"
     And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
     And an existing user "superman" with password "cripto" with super-admin property "yes"
     And following users exist in the application:
       | user           |
       | pietro.alpin   |
       | Hari.seldon    |
       | tomclancy      |
       | publisher      |
       | Peter.sellers  |
       | tom.sawyer     |
     And following users exist with the indicated role in Domain "My Parent Domain"
       | user           | role    |
       | pietro.alpin   | watch   |
       | tom.sawyer     | admin   |
     When "app-admin" tries to list all users available to set custom permissions in Domain "My Parent Domain"
     Then the system returns an user list with following data:
       | user           |
       | Hari.seldon    |
       | Peter.sellers  |
       | publisher      |
       | tomclancy      |


    Scenario: List of users available for setting custom permission in a Domain
      Given an existing Domain called "My Parent Domain"
      And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
      And an existing user "superman" with password "cripto" with super-admin property "yes"
      And following users exist in the application:
        | user           |
        | pietro.alpin   |
        | Hari.seldon    |
        | tomclancy      |
        | publisher      |
        | Peter.sellers  |
        | tom.sawyer     |
      And following users exist with the indicated role in Domain "My Child Domain"
        | user           | role    |
        | pietro.alpin   | watch   |
        | tom.sawyer     | admin   |
      When "app-admin" tries to list all users available to set custom permissions in Domain "My Child Domain"
      Then the system returns an user list with following data:
        | user           |
        | Hari.seldon    |
        | Peter.sellers  |
        | publisher      |
        | tomclancy      |
