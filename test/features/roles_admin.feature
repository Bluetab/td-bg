Feature: Roles Admin
  Authenticated users will have a default "watcher" role for all Domain Groups and Data domains
  - App-admin will have "admin" role in all Domain Groups and Data domains
  - An admin in a Domain Group or Data Domain can grant watch, create, publish or admin role in that Group/Domain or its children to any users
  - A user with a role in a Domain Group or Data Domain has that role as default for also for all its children
  - The existing roles in order of level of permissions are admin, publish, create, watch

  Scenario Outline: Granting roles to domain group by group manager
    Given an existing Domain Group called "My Group"
    And an existing Data Domain called "My Domain" child of Domain Group "My Group"
    And following users exist with the indicated role in Domain Group "My Group"
      | user      | role    |
      | watcher   | watch   |
      | creator   | create  |
      | publisher | publish |
      | admin     | admin   |
    When "<user>" grants <role> role to user "johndoe" in Domain Group "My Group"
    Then the system returns a result with code "<code>"
    And if result "<code>" is "Created", the user "johndoe" has "<group_role>" role in Domain Group "My Group"
    And if result "<code>" is "Created", the user "johndoe" has "<domain_role>" role in Data Domain "My Domain"

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
