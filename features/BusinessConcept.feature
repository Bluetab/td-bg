Feature: Business Concepts administration
  A business concept has a workflow with following status depending on the executed action:
     | initial status   | action            | new status       |
     |                  | create            | draft            |
     | draft            | modification      | draft            |
     | draft            | send for approval | pending approval |
     | draft            | delete            | deleted          |
     | pending approval | publish           | published        |
     | pending approval | reject            | rejected         |
     | rejected         | delete            | deleted          |
     | rejected         | modification      | draft            |
     | rejected         | send for approval | pending approval |
     | published        | modification      | draft            |
     | published        | deprecate         | deprecated       |

  Users will be able to run actions depending on the role they have in the
  Business Concept's Data Domain:
    |          | create  | modification | send for approval | delete | publish | reject | deprecate |
    | admin    |    X    |      X       |        X          |   X    |    X    |   X    |     X     |
    | publish  |    X    |      X       |        X          |   X    |    X    |   X    |     X     |
    | create   |    X    |      X       |        X          |   X    |         |        |           |
    | watch    |         |              |                   |        |         |        |           |

  In this feature we cover the creation as draft, modification, publishing and deletion
  of business concepts.
  Concepts are used by the business to declare the common language that is going
  to be used by the whole organization, the rules to be followed by the data and
  the relations between concepts.
  Relation between concept types is defined at a concept type level.
  Concepts must be unique by domain and name.

  # Background:
  #   Given an existing Domain Group called "My Parent Group"
  #   And an existing Domain Group called "My Child Group" child of Domain Group "My Parent Group"
  #   And an existing Data Domain called "My Domain" child of Domain Group "My Child Group"
  #   And existing users with the correspoding role in Data Domain "My Domain"
  #     | user      | role    |
  #     | watcher   | watch   |
  #     | creator   | create  |
  #     | publisher | publish |
  #     | admin     | admin   |
  #   And an existing Business Concept type called "Business Term" with following data:
  #    | Field            | Format           | Values                                       | Mandatory | Default Value |
  #    | Name             | char(20)         |                                              |    YES    |               |
  #    | Description      | char(500)        |                                              |    YES    |               |
  #    | Formula          | char(100)        |                                              |    NO     |               |
  #    | Format           | List of values   | Date, Numeric, Amount, Text                  |    YES    |               |
  #    | List of Values   | List of char(100)|                                              |    NO     |               |
  #    | Sensitve Data    | List of values   | N/A, Personal Data, Related to personal Data |    YES    | N/A           |
  #    | Update Frequence | List of Values   | Not defined, Daily, Weekly, Monthly, Yearly  |    YES    | Not defined   |
  #    | Related Area     | Char(100)        |                                              |    NO     |               |
  #    | Default Value    | Char(100)        |                                              |    NO     |               |
  #    | Additional Data  | char(500)        |                                              |    NO     |               |

  Scenario Outline: Creating a simple date business concept
    Given an existing Domain Group called "My Parent Group"
    And an existing Domain Group called "My Child Group" child of Domain Group "My Parent Group"
    And an existing Data Domain called "My Domain" child of Domain Group "My Child Group"
    And follwinig users exist with the indicated role in Data Domain "My Domain"
      | user      | role    |
      | watcher   | watch   |
      | creator   | create  |
      | publisher | publish |
      | admin     | admin   |
    And an existing Business Concept type called "Business Term" with following data:
     | Field            | Format           | Values                                       | Mandatory | Default Value |
     | Name             | char(40)         |                                              |    YES    |               |
     | Description      | char(500)        |                                              |    YES    |               |
     | Formula          | char(100)        |                                              |    NO     |               |
     | Format           | List of values   | Date, Numeric, Amount, Text                  |    YES    |               |
     | List of Values   | List of char(100)|                                              |    NO     |               |
     | Sensitve Data    | List of values   | N/A, Personal Data, Related to personal Data |    YES    | N/A           |
     | Update Frequence | List of Values   | Not defined, Daily, Weekly, Monthly, Yearly  |    YES    | Not defined   |
     | Related Area     | Char(100)        |                                              |    NO     |               |
     | Default Value    | Char(100)        |                                              |    NO     |               |
     | Additional Data  | char(500)        |                                              |    NO     |               |
    When <user> tries to create a business concept in the Data Domain "My Domain" with following data:
      | Type          | Name                  | Description                                                       | Format |
      | Business Term | My Date Business Term | This is the first description of my business term which is a date | Date   |
    Then the system returns a result with code <result>
    And if result <result> is "Created", <user> is able to view business concept "My Date Business Term" as a child of Data Domain "My Domain"
    And the user list <users> are <able> to see the business concept "My Date Business Term" with <status> status and following data:
     | Field             | Value                                                              |
     | Name              | My Date Business Term                                              |
     | Type              | Business Term                                                      |
     | Description       | This is the first description of my business term which is a date  |
     | Formula           |                                                                    |
     | Format            | Date                                                               |
     | List of Values    |                                                                    |
     | Sensitve Data     | N/A                                                                |
     | Update Frequence  | Not defined                                                        |
     | Related Area      |                                                                    |
     | Default Value     |                                                                    |
     | Additional Data   |                                                                    |
     | Last Modification | Some timestamp                                                     |
     | Last User         | app-admin                                                          |
     | Version           | 1                                                                  |

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
