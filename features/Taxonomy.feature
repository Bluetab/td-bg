Feature: Taxonomy administration
  This feature will allow to create all levels of taxonomy necessary to classify the content defined within the application.
  We will have data domains as containers of content and Domain Groups as grouping entities for domains or other Domain Groups

  Background:
    Given a logged user "app-administrator" with the "super-admin" role in the application
    And a logged user "group-administrator" with the "admin" role in in the "Riesgos" Domain Group
    And a logged user "data-owner" with the "admin" role in the "Riesgos de crédito" domain
    And a logged user "watcher" with the "watcher" role in the "Riesgos de crédito" domain
    And a logged user "creator" with the "creation" role in the "Riesgos de crédito" domain
    And a logged user "publisher" with the "publish" role in the "Riesgos de crédito" domain

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
