Feature: Roles Admin
  Authenticated users will have a default "watcher" role for all Domain Groups and Data domains
  - App-admin will have "admin" role in all Domain Groups and Data domains
  - An admin in a Domain Group or Data Domain can grant watch, create, publish or admin role in that Group/Domain or its children to any users
  - A user with a role in a Domain Group or Data Domain has that role as default for also for all its children
  - The existing roles in order of level of permissions are admin, publish, create, watch

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

  Scenario Outline: Creating a Domain Group without any dependencies
    When <user> tries to create a Domain Group with the name "Métricas Financieras"
    Then the system returns a result with code <result>
    And the user list <users> is <able> to see the Domain Group "Métricas Financieras"

    Examples:
      | user                 | result    | users                                                                           | able     |
      | app-administrator    | Created   | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
      | group-administrator  | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
      | data-owner           | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
      | watcher              | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
      | creator              | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
      | publisher            | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |

  Scenario Outline: Creating a Domain Group depending on an existing Domain Group
    Given a Domain Group called "Riesgos" with following data:
      | Description |
      | First version of Riesgos |
    When <user> tries to create a Domain Group with the name "Mercados" depending on Domain Group "Riesgos"
    Then the system returns a result with code <result>
    And the user list <users> is <able> to see the Domain Group "Mercados"

    Examples:
      | user                 | result    | users                                                                           | able     |
      | app-administrator    | Created   | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
      | group-administrator  | Created   | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
      | data-owner           | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
      | watcher              | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
      | creator              | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
      | publisher            | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |

  Scenario Outline: Creating a Data Domain depending on an existing Domain Group
    Given a Domain Group called "Riesgos" with following data:
      | Description |
      | First version of Riesgos |
    When <user> tries to create a Data Domain with the name "Riesgo Operacional" depending on Domain Group "Riesgos"
    Then the system returns a result with code <result>
    And the user list <users> is <able> to see the Domain Group "Riesgo Operacional"

    Examples:
      | user                 | result    | users                                                                           | able     |
      | app-administrator    | Created   | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
      | group-administrator  | Created   | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
      | data-owner           | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
      | watcher              | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
      | creator              | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
      | publisher            | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |

  Scenario Outline: Modifying a Domain Group and seeing the new version
    Given a Domain Group called "Riesgos" with following data:
      | Description |
      | First version of Riesgos |
    When <user> tries to modify a Domain Group with the name "Riesgos" introducing following data:
      | Description |
      | Second version of Riesgos |
    Then the system returns a result with code <result>
    And the user list <users> is <able> to see the Domain Group "Riesgos" with following data:
      | Description |
      | Second version of Riesgos |

    Examples:
      | user                 | result    | users                                                                           | able     |
      | app-administrator    | Ok        | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
      | group-administrator  | Ok        | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
      | data-owner           | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
      | watcher              | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
      | creator              | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
      | publisher            | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |

  Scenario Outline: Modifying a Domain Group and seeing the old version
    Given a Domain Group called "Riesgos" with following data:
      | Description |
      | First version of Riesgos |
    When <user> tries to modify a Domain Group with the name "Riesgos" introducing following data:
      | Description |
      | Second version of Riesgos |
    Then the system returns a result with code <result>
    And the user list <users> is <able> to see the Domain Group "Riesgos" with following data:
      | Description |
      | First version of Riesgos |

    Examples:
      | user                 | result    | users                                                                           | able     |
      | app-administrator    | Ok        | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
      | group-administrator  | Ok        | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
      | data-owner           | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
      | watcher              | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
      | creator              | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
      | publisher            | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |

    Scenario Outline: Modifying a Data Domain and seeing the new version
      Given a Domain Group called "Riesgos" with following data:
        | Description |
        | First version of Riesgos |
      And a Data Domain called "Riesgos de Crédito" belonging to Domain Group "Riesgos" with following data:
        | Description |
        | First version of Riesgos de Crédito |
      When <user> tries to modify a Data Domain with the name "Riesgos de Crédito" introducing following data:
        | Description |
        | Second version of Riesgos de Crédito |
      Then the system returns a result with code <result>
      And the user list <users> is <able> to see the Data Domain "Riesgos de Crédito" with following data:
        | Description |
        | Second version of Riesgos de Crédito |

      Examples:
        | user                 | result    | users                                                                           | able     |
        | app-administrator    | Ok        | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
        | group-administrator  | Ok        | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
        | data-owner           | Ok        | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
        | watcher              | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
        | creator              | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
        | publisher            | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |

    Scenario Outline: Modifying a Data Domain and seeing the new version
      Given a Domain Group called "Riesgos" with following data:
        | Description |
        | First version of Riesgos |
      And a Data Domain called "Riesgos de Crédito" belonging to Domain Group "Riesgos" with following data:
        | Description |
        | First version of Riesgos de Crédito |
      When <user> tries to modify a Data Domain with the name "Riesgos de Crédito" introducing following data:
        | Description |
        | Second version of Riesgos de Crédito |
      Then the system returns a result with code <result>
      And the user list <users> is <able> to see the Data Domain "Riesgos de Crédito" with following data:
        | Description |
        | First version of Riesgos de Crédito |

      Examples:
        | user                 | result    | users                                                                           | able     |
        | app-administrator    | Ok        | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
        | group-administrator  | Ok        | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
        | data-owner           | Ok        | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
        | watcher              | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
        | creator              | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
        | publisher            | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |

    Scenario Outline: Deleting a Domain Group without any Group or Domain pending on it
      Given Domain Group "No-Data" that has no children
      And a logged user "no-data-administrator" with the "admin" role in the "No-Data" Domain Group
      When <user> tries to delete a Domain Group with the name "No-Data"
      Then the system returns a result with code <result>
      And the user list <users> is able to see the Data Domain "No-Data" with following data:

      Examples:
        | user                  | result    | users                                                                           | able     |
        | app-administrator     | Ok        | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
        | group-administrator   | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
        | no-data-administrator | Ok        | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
        | data-owner            | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
        | watcher               | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
        | creator               | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
        | publisher             | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |

    Scenario Outline: Deleting a Domain Group with a Data Domain pending on it
      Given a Domain Group called "Riesgos" with following data:
        | Description |
        | First version of Riesgos |
      When <user> tries to delete a Domain Group with the name "Riesgos"
      Then the system returns a result with code <result>
      And the user list <users> is able to see the Data Domain "Riesgos" with following data:

      Examples:
        | user                  | result    | users                                                                           | able     |
        | app-administrator     | Ok        | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
        | group-administrator   | Ok        | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
        | data-owner            | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
        | watcher               | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
        | creator               | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
        | publisher             | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |

    Scenario Outline: User should be able to delete a Data Domain that has no business concepts pending on them
      Given a Domain Group called "Riesgos" with following data:
        | Description |
        | First version of Riesgos |
      And a Data Domain called "Riesgos de Crédito" belonging to Domain Group "Riesgos" with following data:
        | Description |
        | First version of Riesgos de Crédito |
      When <user> tries to delete a Domain Group with the name "Riesgos de Crédito"
      Then the system returns a result with code <result>
      And the user list <users> is able to see the Data Domain "Riesgos de Crédito" with following data:

      Examples:
        | user                  | result    | users                                                                           | able     |
        | app-administrator     | Ok        | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
        | group-administrator   | Ok        | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
        | data-owner            | Ok        | app-administrator, group-administrator, data-owner, watcher, creator, publisher | not able |
        | watcher               | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
        | creator               | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
        | publisher             | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |

    Scenario Outline: User should not be able to delete a Data Domain that has business concepts pending on them
      Given a Domain Group called "Riesgos" with following data:
        | Description |
        | First version of Riesgos |
      And a Data Domain called "Riesgos de Crédito" belonging to Domain Group "Riesgos" with following data:
        | Description |
        | First version of Riesgos de Crédito |
      And an existing business concept with the name "Riesgos Compuesto" in the "Riesgos de Crédito" domain in "Published" status
      When <user> tries to delete a Domain Group with the name "Riesgos de Crédito"
      Then the system returns a result with code <result>
      And the user list <users> is able to see the Data Domain "Riesgos de Crédito" with following data:

      Examples:
        | user                  | result    | users                                                                           | able     |
        | app-administrator     | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
        | group-administrator   | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
        | data-owner            | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
        | watcher               | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
        | creator               | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
        | publisher             | Forbidden | app-administrator, group-administrator, data-owner, watcher, creator, publisher | able     |
