Feature: Taxonomy administration
  This feature will allow to create all levels of taxonomy necessary to classify the content defined within the application.
  We will have data domains as containers of content and Domain Groups as grouping entities for domains or other Domain Groups

  Background:
    Given an existing Domain Group called "Parent Group" with following data:
      | Description |
      | First version of Parent Group |
    And an existing Domain Group called "Child Group" as child of Domain Group "Parent Group" with following data:
      | Description |
      | First version of Child Group |
    And an existing Data Domain called "My Domain" as child of Domain Group "Child Group" with following data:
      | Description |
      | First version of My Domain |
    And an existing user "pg-admin" with password "pas2w0rd" without "super-admin" permission
    And an existing user "pg-publisher" with password "pas2w0rd" without "super-admin" permission
    And an existing user "pg-creator" with password "pas2w0rd" without "super-admin" permission
    And an existing user "pg-watcher" with password "pas2w0rd" without "super-admin" permission
    And an existing user "cg-admin" with password "pas2w0rd" without "super-admin" permission
    And an existing user "cg-publisher" with password "pas2w0rd" without "super-admin" permission
    And an existing user "cg-creator" with password "pas2w0rd" without "super-admin" permission
    And an existing user "cg-watcher" with password "pas2w0rd" without "super-admin" permission
    And an existing user "d-admin" with password "pas2w0rd" without "super-admin" permission
    And an existing user "d-publisher" with password "pas2w0rd" without "super-admin" permission
    And an existing user "d-creator" with password "pas2w0rd" without "super-admin" permission
    And an existing user "d-watcher" with password "pas2w0rd" without "super-admin" permission
    And user "pg-admin" has been granted role "admin" to Domain Group "Parent Group"
    And user "pg-publisher" has been granted role "publish" to Domain Group "Parent Group"
    And user "pg-creator" has been granted role "create" to Domain Group "Parent Group"
    And user "cg-admin" has been granted role "admin" to Domain Group "Child Group"
    And user "cg-publisher" has been granted role "publish" to Domain Group "Child Group"
    And user "cg-creator" has been granted role "create" to Domain Group "Child Group"
    And user "d-admin" has been granted role "admin" to Data Domain "My Domain"
    And user "d-publisher" has been granted role "publish" Data Domain "My Domain"
    And user "d-creator" has been granted role "create" Data Domain "My Domain"

  Scenario Outline: Creating a Domain Group without any parent is not allowed for any user but the super admins
    When user <user> tries to create a Domain Group with the name "Second Parent Group" and following data:
      | Description |
      | First version of Second Parent Group |
    Then the system returns a result with code <result>
    And the user "app-admin" is <able> to see the Domain Group "Second Parent Group" with following data:
      | Description |
      | First version of Second Parent Group |

    Examples:
      | user                 | result    | able     |
      | pg-admin             | Forbidden | not able |
      | pg-publisher         | Forbidden | not able |
      | pg-creator           | Forbidden | not able |
      | pg-watcher           | Forbidden | not able |
      | cg-admin             | Forbidden | not able |
      | cg-publisher         | Forbidden | not able |
      | cg-creator           | Forbidden | not able |
      | cg-watcher           | Forbidden | not able |

  Scenario Outline: Creating a Domain Group depending of an existing Domain Group
    When user <user> tries to create a Domain Group with the name "Second Child Group" as child of Domain Group "Parent Group" with following data:
      | Description |
      | First version of Second Child Group |
    Then the system returns a result with code <result>
    And the user "app-admin" is <able> to see the Domain Group "Second Child Group" with following data:
      | Description |
      | First version of Second Child Group |

    Examples:
      | user                 | result    | able     |
      | pg-admin             | Ok        | able     |
      | pg-publisher         | Forbidden | not able |
      | pg-creator           | Forbidden | not able |
      | pg-watcher           | Forbidden | not able |
      | cg-admin             | Forbidden | not able |
      | cg-publisher         | Forbidden | not able |
      | cg-creator           | Forbidden | not able |
      | cg-watcher           | Forbidden | not able |
      | d-admin              | Forbidden | not able |
      | d-publisher          | Forbidden | not able |
      | d-creator            | Forbidden | not able |
      | d-watcher            | Forbidden | not able |

  Scenario Outline: Creating a Domain Group as child of an existing Domain Group which has another group as parent
    When user <user> tries to create a Domain Group with the name "Grandchild Group" as child of Domain Group "Child Group" with following data:
      | Description |
      | First version of Second Grandchild Group |
    Then the system returns a result with code <result>
    And the user "app-admin" is <able> to see the Domain Group "Grandchild Group" with following data:
      | Description |
      | First version of Second Grandchild Group |

    Examples:
      | user                 | result    | able     |
      | pg-admin             | Ok        | able     |
      | pg-publisher         | Forbidden | not able |
      | pg-creator           | Forbidden | not able |
      | pg-watcher           | Forbidden | not able |
      | cg-admin             | Ok        | able     |
      | cg-publisher         | Forbidden | not able |
      | cg-creator           | Forbidden | not able |
      | cg-watcher           | Forbidden | not able |
      | d-admin              | Forbidden | not able |
      | d-publisher          | Forbidden | not able |
      | d-creator            | Forbidden | not able |
      | d-watcher            | Forbidden | not able |

  Scenario Outline: Creating a Data Domain depending on an existing Domain Group
    When <user> tries to create a Data Domain with the name "My Second Domain" depending on Domain Group "Child Group" with following data:
      | Description |
      | First version of My Second Domain |
    Then the system returns a result with code <result>
    And the user "app-admin" is <able> to see the Data Domain "My Second Domain" with following data:
      | Description |
      | First version of My Second Domain |

    Examples:
      | user                 | result    | able     |
      | pg-admin             | Ok        | able     |
      | pg-publisher         | Forbidden | not able |
      | pg-creator           | Forbidden | not able |
      | pg-watcher           | Forbidden | not able |
      | cg-admin             | Ok        | able     |
      | cg-publisher         | Forbidden | not able |
      | cg-creator           | Forbidden | not able |
      | cg-watcher           | Forbidden | not able |
      | d-admin              | Forbidden | not able |
      | d-publisher          | Forbidden | not able |
      | d-creator            | Forbidden | not able |
      | d-watcher            | Forbidden | not able |

  Scenario Outline: Modifying a Parent Domain Group and seeing the new version
    When <user> tries to modify a Domain Group with the name "Parent Domain" introducing following data:
      | Description |
      | Second version of Parent Domain |
    Then the system returns a result with code <result>
    And the user "app-admin" is <able> to see the Domain Group "Parent Domain" with following data:
      | Description |
      | Second version of Parent Domain |

    Examples:
      | user                 | result    | able     |
      | pg-admin             | Ok        | able     |
      | pg-publisher         | Forbidden | not able |
      | pg-creator           | Forbidden | not able |
      | pg-watcher           | Forbidden | not able |
      | cg-admin             | Forbidden | not able |
      | cg-publisher         | Forbidden | not able |
      | cg-creator           | Forbidden | not able |
      | cg-watcher           | Forbidden | not able |
      | d-admin              | Forbidden | not able |
      | d-publisher          | Forbidden | not able |
      | d-creator            | Forbidden | not able |
      | d-watcher            | Forbidden | not able |

  Scenario Outline: Modifying a Child Domain Group and seeing the new version
    When <user> tries to modify a Domain Group with the name "Child Domain" introducing following data:
      | Description |
      | Second version of Child Domain |
    Then the system returns a result with code <result>
    And the user "app-admin" is <able> to see the Domain Group "Child Domain" with following data:
      | Description |
      | Second version of Child Domain |

    Examples:
      | user                 | result    | able     |
      | pg-admin             | Ok        | able     |
      | pg-publisher         | Forbidden | not able |
      | pg-creator           | Forbidden | not able |
      | pg-watcher           | Forbidden | not able |
      | cg-admin             | Ok        | not able |
      | cg-publisher         | Forbidden | not able |
      | cg-creator           | Forbidden | not able |
      | cg-watcher           | Forbidden | not able |
      | d-admin              | Forbidden | not able |
      | d-publisher          | Forbidden | not able |
      | d-creator            | Forbidden | not able |
      | d-watcher            | Forbidden | not able |

    Scenario Outline: Modifying a Data Domain
      When <user> tries to modify a Data Domain with the name "My Domain" with following data:
        | Description |
        | Second version of My Domain |
      Then the system returns a result with code <result>
      And the user "app-admin" is <able> to see the Data Domain "My Domain" with following data:
        | Description |
        | Second version of My Domain |

      Examples:
        | user                 | result    | able     |
        | pg-admin             | Ok        | able     |
        | pg-publisher         | Forbidden | not able |
        | pg-creator           | Forbidden | not able |
        | pg-watcher           | Forbidden | not able |
        | cg-admin             | Ok        | not able |
        | cg-publisher         | Forbidden | not able |
        | cg-creator           | Forbidden | not able |
        | cg-watcher           | Forbidden | not able |
        | d-admin              | Ok        | not able |
        | d-publisher          | Forbidden | not able |
        | d-creator            | Forbidden | not able |
        | d-watcher            | Forbidden | not able |

    Scenario Outline: Deleting a Domain Group without any Group or Domain as child
      Given an existing Domain Group called "Emtpy Child" as child of Domain Group "Parent Group" with following data:
        | Description |
        | First version of Empty Child |
      And an existing user "eg-admin" with password "pas2w0rd" without "super-admin" permission
      And user "eg-admin" has been granted role "admin" to Domain Group "Emtpy Child"
      When <user> tries to delete a Domain Group with the name "Empty Child"
      Then the system returns a result with code <result>
      And the user "app-admin" is <able> to see the Domain Group "Empty Group" with following data:
        | Description |
        | First version of Empty Child |

      Examples:
        | user                 | result    | able     |
        | eg-admin             | Ok        | not able |
        | pg-admin             | Ok        | not able |
        | pg-publisher         | Forbidden | able     |
        | pg-creator           | Forbidden | able     |
        | pg-watcher           | Forbidden | able     |
        | cg-admin             | Forbidden | able     |
        | cg-publisher         | Forbidden | able     |
        | cg-creator           | Forbidden | able     |
        | cg-watcher           | Forbidden | able     |
        | d-admin              | Forbidden | able     |
        | d-publisher          | Forbidden | able     |
        | d-creator            | Forbidden | able     |
        | d-watcher            | Forbidden | able     |

    Scenario Outline: Deleting a Domain Group with a Data Domain pending on it
      When <user> tries to delete a Domain Group with the name "Child Group"
      Then the system returns a result with code <result>
      And the user "app-admin" is <able> to see the Domain Group "Child Group" with following data:
        | Description |
        | First version of Child Group |

      Examples:
        | user                 | result    | able     |
        | pg-admin             | Forbidden | able     |
        | pg-publisher         | Forbidden | able     |
        | pg-creator           | Forbidden | able     |
        | pg-watcher           | Forbidden | able     |
        | cg-admin             | Forbidden | able     |
        | cg-publisher         | Forbidden | able     |
        | cg-creator           | Forbidden | able     |
        | cg-watcher           | Forbidden | able     |
        | d-admin              | Forbidden | able     |
        | d-publisher          | Forbidden | able     |
        | d-creator            | Forbidden | able     |
        | d-watcher            | Forbidden | able     |

    Scenario Outline: User should be able to delete a Data Domain that has no business concepts pending on them
      When <user> tries to delete a Data Domain with the name "My Domain"
      Then the system returns a result with code <result>
      And the user list <users> is able to see the Data Domain "My Domain" with following data:
        | Description |
        | First version of My Domain |

      Examples:
        | user                 | result    | able     |
        | pg-admin             | Ok        | not able |
        | pg-publisher         | Forbidden | able     |
        | pg-creator           | Forbidden | able     |
        | pg-watcher           | Forbidden | able     |
        | cg-admin             | Ok        | not able |
        | cg-publisher         | Forbidden | able     |
        | cg-creator           | Forbidden | able     |
        | cg-watcher           | Forbidden | able     |
        | d-admin              | Ok        | not able |
        | d-publisher          | Forbidden | able     |
        | d-creator            | Forbidden | able     |
        | d-watcher            | Forbidden | able     |
