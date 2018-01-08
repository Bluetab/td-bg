Feature: Business Concepts administration
  In this feature we cover the creation as draft, modification, publishing and deletion
  of business concepts.
  Concepts are used by the business to declare the common language that is going
  to be used by the whole organization, the rules to be followed by the data and
  the relations between concepts.
  Relation between concept types is defined at a concept type level.
  Concepts must be unique by domain and name.

  Background:
    Given a data domain called "Saldos"
    And a logged user "watcher" with the "watcher" role in the "Saldos" domain
    And a logged user "creator" with the "creation" role in the "Saldos" domain
    And a logged user "publisher" with the "publish" role in the "Saldos" domain
    And a logged user "creator2" with the "creation" role in the "Saldos" domain
    And a logged user "publisher2" with the "publish" role in the "Saldos" domain

  Scenario Outline: Creating a business concept
    When <user> tries to create a business concept with the name "Saldo medio" in the "Saldos" domain
    Then the system returns a result with code <result>
    And the user list <users> is <able> to see the business concept "Saldo Medio" in <status> status

    Examples:
      | user      | result    | users                       | able       | status |
      | watcher   | Forbidden | watcher, creator, publisher | not able   | draft  |
      | creator   | Created   | watcher                     | not able   | draft  |
      | creator   | Created   | creator, publisher          | able       | draft  |
      | publisher | Created   | watcher                     | not able   | draft  |
      | publisher | Created   | creator, publisher          | able       | draft  |


  Scenario: A user with create privileges tries to create a duplicated concept
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Draft" status
    When user "creator" tries to create a business concept with the name "Saldo Medio"
    Then the system returns an error with code "Forbidden"
    And the user "watcher" can't see the business concept "Saldo Medio"
    And the user "creator" can't see the business concept "Saldo Medio" in "draft" status

  Scenario Outline: Publishing a business concept
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in <initial_status>
    When <user> tries to publish a business concept with the name "Saldo medio" in the "Saldos" domain
    Then the system returns a result with code <result>
    And the user list <users> is <able> to see the business concept "Saldo Medio" in <status> status

    Examples:
      | user      | initial_status | result    | users                       | able       | status     |
      | watcher   | draft          | Forbidden | watcher                     | not able   | any_status |
      | watcher   | draft          | Forbidden | watcher, creator, publisher | not able   | published  |
      | creator   | draft          | Forbidden | watcher, creator, publisher | not able   | published  |
      | publisher | draft          | Ok        | watcher, creator, publisher | able       | published  |
      | publisher | draft          | Ok        | watcher, creator, publisher | not able   | draft      |
      | watcher   | published      | Forbidden | watcher, creator, publisher | able       | published  |
      | creator   | published      | Forbidden | watcher, creator, publisher | able       | published  |
      | publisher | published      | Forbidden | watcher, creator, publisher | able       | published  |

  Scenario Outline: Creating and publishing a business concept in one action
    When <user> tries to create and publish a business concept with the name "Saldo medio" in the "Saldos" domain
    Then the system returns a result with code <result>
    And the user list <users> is <able> to see the business concept "Saldo Medio" in <status> status

    Examples:
      | user      | result    | users                       | able       | status     |
      | watcher   | Forbidden | watcher, creator, publisher | not able   | any_status |
      | creator   | Forbidden | watcher, creator, publisher | not able   | any_status |
      | publisher | Created   | watcher, creator, publisher | able       | published  |

  Scenario Outline: Modifying a Business Concept and seeing the old version
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain with <status> status with the following data:
      | Description |
      | First version of saldo medio |
    When <user> tries to modify a business concept with the name "Saldo medio" in the "Saldos" domain using following data:
      | Description |
      | Second version of saldo medio |
    Then the system returns a result with code <result>
    And the user list <users> is <able> to see the business concept "Saldo Medio" in <new_status> status with Following Data:
      | Description |
      | First version of saldo medio |

    Examples:
      | user      | status         | result    | users                       | able       | new_status |
      | watcher   | draft          | Forbidden | watcher                     | not able   | draft      |
      | watcher   | draft          | Forbidden | creator, publisher          | able       | draft      |
      | creator   | draft          | Ok        | watcher, creator, publisher | not able   | draft      |
      | publisher | draft          | Ok        | watcher, creator, publisher | not able   | draft      |
      | watcher   | published      | Forbidden | watcher, creator, publisher | not able   | draft      |
      | creator   | published      | Ok        | watcher, creator, publisher | not able   | draft      |
      | publisher | published      | Ok        | watcher, creator, publisher | not able   | draft      |
      | watcher   | published      | Forbidden | watcher, creator, publisher | able       | published  |
      | creator   | published      | Ok        | watcher, creator, publisher | able       | published  |
      | publisher | published      | Ok        | watcher, creator, publisher | able       | published  |

  Scenario Outline: Modifying a Business Concept and seeing the new draft version
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain with <status> status with the following data:
      | Description |
      | First version of saldo medio |
    When <user> tries to modify a business concept with the name "Saldo medio" in the "Saldos" domain using following data:
      | Description |
      | Second version of saldo medio |
    Then the system returns a result with code <result>
    And the user list <users> is <able> to see the business concept "Saldo Medio" in <new_status> status with Following Data:
      | Description |
      | Second version of saldo medio |

    Examples:
      | user      | status         | result    | users                       | able       | new_status |
      | watcher   | draft          | Forbidden | watcher                     | not able   | draft      |
      | watcher   | draft          | Forbidden | creator, publisher          | able       | draft      |
      | creator   | draft          | Ok        | watcher, creator, publisher | able       | draft      |
      | publisher | draft          | Ok        | watcher, creator, publisher | able       | draft      |
      | watcher   | published      | Forbidden | watcher, creator, publisher | not able   | draft      |
      | creator   | published      | Ok        | watcher, creator, publisher | able       | draft      |
      | publisher | published      | Ok        | watcher, creator, publisher | able       | draft      |
      | watcher   | published      | Forbidden | watcher, creator, publisher | not able   | published  |
      | creator   | published      | Ok        | watcher, creator, publisher | not able   | published  |
      | publisher | published      | Ok        | watcher, creator, publisher | not able   | published  |

  Scenario Outline: Depecrating a Business Concept
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain with <status> status
    When <user> tries to deprecate a business concept with the name "Saldo medio" in the "Saldos" domain
    Then the system returns a result with code <result>
    And the user list <users> is <able> to see the business concept "Saldo Medio" in <new_status> status

    Examples:
      | user      | status         | result    | users                       | able       | new_status |
      | watcher   | draft          | Forbidden | watcher, creator, publisher | not able   | deprecated |
      | watcher   | draft          | Forbidden | watcher                     | not able   | draft      |
      | watcher   | draft          | Forbidden | creator, publisher          | able       | draft      |
      | creator   | draft          | Forbidden | watcher, creator, publisher | not able   | deprecated |
      | creator   | draft          | Forbidden | watcher                     | not able   | draft      |
      | creator   | draft          | Forbidden | creator, publisher          | able       | draft      |
      | publisher | draft          | Ok        | watcher, creator, publisher | not able   | draft      |
      | publisher | draft          | Ok        | watcher, creator, publisher | able       | deprecated |
      | watcher   | published      | Forbidden | watcher, creator, publisher | not able   | deprecated |
      | watcher   | published      | Forbidden | watcher, creator, publisher | able       | published  |
      | creator   | published      | Forbidden | watcher, creator, publisher | not able   | deprecated |
      | creator   | published      | Forbidden | watcher, creator, publisher | able       | published  |
      | publisher | published      | Ok        | watcher, creator, publisher | not able   | published  |
      | publisher | published      | Ok        | watcher, creator, publisher | able       | deprecated |
