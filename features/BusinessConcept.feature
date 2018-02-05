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
    |          | create  | modification | send for approval | delete | publish | reject | deprecate | see draft | see published |
    | admin    |    X    |      X       |        X          |   X    |    X    |   X    |     X     |     X     |     X         |
    | publish  |    X    |      X       |        X          |   X    |    X    |   X    |     X     |     X     |     X         |
    | create   |    X    |      X       |        X          |   X    |         |        |           |     X     |     X         |
    | watch    |         |              |                   |        |         |        |           |           |     X         |

  In this feature we cover the creation as draft, modification, publishing and deletion
  of business concepts.
  Concepts are used by the business to declare the common language that is going
  to be used by the whole organization, the rules to be followed by the data and
  the relations between concepts.
  Relation between concept types is defined at a concept type level.
  Concepts must be unique by domain and name.

  Scenario: Create a simple business concept
    Given an existing Domain Group called "My Parent Group"
    And an existing Domain Group called "My Child Group" child of Domain Group "My Parent Group"
    And an existing Data Domain called "My Domain" child of Domain Group "My Child Group"
    And an existing Business Concept type called "Business Term" with empty definition
    And user "app-admin" is logged in the application with password "mypass"
    When "app-admin" tries to create a business concept in the Data Domain "My Domain" with following data:
      | Field             | Value                                                                   |
      | Type              | Business Term                                                           |
      | Name              | My Simple Business Term                                                 |
      | Description       | This is the first description of my business term which is very simple  |
    Then the system returns a result with code "Created"
    And "app-admin" is able to view business concept "My Simple Business Term" as a child of Data Domain "My Domain" with following data:
      | Field             | Value                                                                    |
      | Type              | Business Term                                                            |
      | Name              | My Simple Business Term                                                  |
      | Description       | This is the first description of my business term which is very simple   |
      | Status            | draft                                                                    |
      | Last Modification | Some Timestamp                                                           |
      | Last user         | app-admin                                                                |
      | Version           | 1                                                                        |

  Scenario: Create a business concept with dinamic data
    Given an existing Domain Group called "My Parent Group"
    And an existing Domain Group called "My Child Group" child of Domain Group "My Parent Group"
    And an existing Data Domain called "My Domain" child of Domain Group "My Child Group"
    And an existing Business Concept type called "Business Term" with following definition:
     | Field            | Format        | Max Size | Values                                       | Mandatory | Default Value |
     | Formula          | string        | 100      |                                              |    NO     |               |
     | Format           | list          |          | Date, Numeric, Amount, Text                  |    YES    |               |
     | List of Values   | variable list | 100      |                                              |    NO     |               |
     | Sensitve Data    | list          |          | N/A, Personal Data, Related to personal Data |    NO     | N/A           |
     | Update Frequence | list          |          | Not defined, Daily, Weekly, Monthly, Yearly  |    NO     | Not defined   |
     | Related Area     | string        | 100      |                                              |    NO     |               |
     | Default Value    | string        | 100      |                                              |    NO     |               |
     | Additional Data  | string        | 500      |                                              |    NO     |               |
    And user "app-admin" is logged in the application with password "mypass"
    When "app-admin" tries to create a business concept in the Data Domain "My Domain" with following data:
      | Field             | Value                                                                    |
      | Type              | Business Term                                                            |
      | Name              | My Dinamic Business Term                                                 |
      | Description       | This is the first description of my business term which is a date        |
      | Formula           |                                                                    |
      | Format            | Date                                                                     |
      | List of Values    |                                                                    |
      #| Sensitve Data     | N/A                                                                |
      #| Update Frequence  | Not defined                                                        |
      | Related Area      |                                                                    |
      | Default Value     |                                                                    |
      | Additional Data   |                                                                    |
    Then the system returns a result with code "Created"
    And "app-admin" is able to view business concept "My Dinamic Business Term" as a child of Data Domain "My Domain" with following data:
      | Field             | Value                                                              |
      | Name              | My Dinamic Business Term                                           |
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
      | Status            | draft                                                              |
      | Last Modification | Some timestamp                                                     |
      | Last User         | app-admin                                                          |
      | Version           | 1                                                                  |

  Scenario Outline: Creating a business concept depending on your role
    Given an existing Domain Group called "My Parent Group"
    And an existing Domain Group called "My Child Group" child of Domain Group "My Parent Group"
    And an existing Data Domain called "My Domain" child of Domain Group "My Child Group"
    And an existing Business Concept type called "Business Term" with empty definition
    And following users exist with the indicated role in Data Domain "My Domain"
      | user      | role    |
      | watcher   | watch   |
      | creator   | create  |
      | publisher | publish |
      | admin     | admin   |
    And user "<user>" is logged in the application with password "<user>"
    When "<user>" tries to create a business concept in the Data Domain "My Domain" with following data:
      | Field             | Value                                                                   |
      | Type              | Business Term                                                           |
      | Name              | My Simple Business Term                                                 |
      | Description       | This is the first description of my business term which is very simple  |
    Then the system returns a result with code "<result>"
    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Created      |
      | publisher | Created      |
      | admin     | Created      |


  Scenario Outline: Modification of existing Business Concept in Draft status
    Given an existing Domain Group called "My Parent Group"
    And an existing Domain Group called "My Child Group" child of Domain Group "My Parent Group"
    And an existing Data Domain called "My Domain" child of Domain Group "My Child Group"
    And following users exist with the indicated role in Data Domain "My Domain"
      | user      | role    |
      | watcher   | watch   |
      | creator   | create  |
      | publisher | publish |
      | admin     | admin   |
    And an existing Business Concept type called "Business Term" with following data:
     | Field            | Format        | Max Size | Values                                       | Mandatory | Default Value |
     | Formula          | string        | 100      |                                              |    NO     |               |
     | Format           | list          |          | Date, Numeric, Amount, Text                  |    YES    |               |
     | List of Values   | variable list | 100      |                                              |    NO     |               |
     | Sensitve Data    | list          |          | N/A, Personal Data, Related to personal Data |    NO     | N/A           |
     | Update Frequence | list          |          | Not defined, Daily, Weekly, Monthly, Yearly  |    NO     | Not defined   |
     | Related Area     | string        | 100      |                                              |    NO     |               |
     | Default Value    | string        | 100      |                                              |    NO     |               |
     | Additional Data  | string        | 500      |                                              |    NO     |               |
    And user "<user>" is logged in the application with password "<user>"
    And an existing Business Concept of type "Business Term" with following data:
      | Type          | Name                  | Description                                                       | Format |
      | Business Term | My Date Business Term | This is the first description of my business term which is a date | Date   |
    When <user> tries to modify a business concept "My Date Business Term" of type "Business Term" with following data:
      | Type          | Name                  | Description                                                        | Format | Sensitive Data           | Update Frequence |
      | Business Term | My Date Business Term | This is the second description of my business term which is a date | Date   | Related to personal Data | Monthly          |
    Then the system returns a result with code <result>
    And if result <result> is "Ok", user <user> is able to view business concept "My Date Business Term" of type "Business Term" with follwing data:
     | Field             | Value                                                              |
     | Name              | My Date Business Term                                              |
     | Type              | Business Term                                                      |
     | Description       | This is the second description of my business term which is a date |
     | Formula           |                                                                    |
     | Format            | Date                                                               |
     | List of Values    |                                                                    |
     | Sensitve Data     | Related to personal Data                                           |
     | Update Frequence  | Monthly                                                            |
     | Related Area      |                                                                    |
     | Default Value     |                                                                    |
     | Additional Data   |                                                                    |
     | Last Modification | Some timestamp                                                     |
     | Last User         | app-admin                                                          |
     | Version           | 1                                                                  |
     | Status            | Draft                                                              |

    Examples:
      | user      | result    |
      | watcher   | Forbidden |
      | creator   | Ok        |
      | publisher | Ok        |
      | admin     | Ok        |

  Scenario Outline: Sending business concept for approval
    Given an existing Domain Group called "My Parent Group"
    And an existing Domain Group called "My Child Group" child of Domain Group "My Parent Group"
    And an existing Data Domain called "My Domain" child of Domain Group "My Child Group"
    And following users exist with the indicated role in Data Domain "My Domain"
      | user      | role    |
      | watcher   | watch   |
      | creator   | create  |
      | publisher | publish |
      | admin     | admin   |
    And an existing Business Concept type called "Business Term" without definition
    And user "<user>" is logged in the application with password "<user>"
    And an existing Business Concept of type "Business Term" with following data:
     | Type          | Name                  | Description                                                       |
     | Business Term | My Date Business Term | This is the first description of my business term which is a date |
    When <user> tries to send for approval a business concept with name "My Date Business Term" of type "Business Term"
    Then the system returns a result with code <result>
    And if result <result> is "Ok", user <user> is able to view business concept "My Date Business Term" of type "Business Term" with follwing data:
     | Field             | Value                                                              |
     | Name              | My Date Business Term                                              |
     | Type              | Business Term                                                      |
     | Description       | This is the first description of my business term which is a date  |
     | Last Modification | Some timestamp                                                     |
     | Last User         | app-admin                                                          |
     | Version           | 1                                                                  |
     | Status            | Pending Approval                                                   |

    Examples:
      | user      | result    |
      | watcher   | Forbidden |
      | creator   | Ok        |
      | publisher | Ok        |
      | admin     | Ok        |

  Scenario: User should not be able to create a business concept with same type and name as an existing one
    Given an existing Domain Group called "My Parent Group"
    And an existing Data Domain called "My Domain" child of Domain Group "My Parent Group"
    And an existing Business Concept type called "Business Term" without definition
    And an existing Business Concept of type "Business Term" with following data:
     | Type          | Name             | Description                                       |
     | Business Term | My Business Term | This is the first description of my business term |
    And an existing Domain Group called "My Second Parent Group"
    And an existing Data Domain called "My Second Domain" child of Domain Group "My Second Parent Group"
    When "app-admin" tries to create a business concept in the Data Domain "My Second Domain" with following data:
     | Type          | Name                    | Description                                 |
     | Business Term | My Business Term | This is the second description of my business term |
    Then the system returns a result with code "Unprocessable Entity"
    And "app-admin" is able to view business concept "My Business Term" as a child of Data Domain "My Domain" with following data:
      | Type          | Name                    | Description                                                            | Status | Last Modification | Last user | Version |
      | Business Term | My Simple Business Term | This is the first description of my business term which is very simple | draft  | Some Timestamp    | app-admin | 1       |
    And "app-admin" is not able to view business concept "My Business Term" as a child of Data Domain "My Second Domain"


  # Scenario: A user with create privileges tries to create a duplicated concept
  #   Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Draft" status
  #   When user "creator" tries to create a business concept with the name "Saldo Medio"
  #   Then the system returns an error with code "Forbidden"
  #   And the user "watcher" can't see the business concept "Saldo Medio"
  #   And the user "creator" can't see the business concept "Saldo Medio" in "draft" status
  #
  # Scenario Outline: Publishing a business concept
  #   Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in <initial_status>
  #   When <user> tries to publish a business concept with the name "Saldo medio" in the "Saldos" domain
  #   Then the system returns a result with code <result>
  #   And the user list <users> is <able> to see the business concept "Saldo Medio" in <status> status
  #
  #   Examples:
  #     | user      | initial_status | result    | users                       | able       | status     |
  #     | watcher   | draft          | Forbidden | watcher                     | not able   | any_status |
  #     | watcher   | draft          | Forbidden | watcher, creator, publisher | not able   | published  |
  #     | creator   | draft          | Forbidden | watcher, creator, publisher | not able   | published  |
  #     | publisher | draft          | Ok        | watcher, creator, publisher | able       | published  |
  #     | publisher | draft          | Ok        | watcher, creator, publisher | not able   | draft      |
  #     | watcher   | published      | Forbidden | watcher, creator, publisher | able       | published  |
  #     | creator   | published      | Forbidden | watcher, creator, publisher | able       | published  |
  #     | publisher | published      | Forbidden | watcher, creator, publisher | able       | published  |
  #
  # Scenario Outline: Creating and publishing a business concept in one action
  #   When <user> tries to create and publish a business concept with the name "Saldo medio" in the "Saldos" domain
  #   Then the system returns a result with code <result>
  #   And the user list <users> is <able> to see the business concept "Saldo Medio" in <status> status
  #
  #   Examples:
  #     | user      | result    | users                       | able       | status     |
  #     | watcher   | Forbidden | watcher, creator, publisher | not able   | any_status |
  #     | creator   | Forbidden | watcher, creator, publisher | not able   | any_status |
  #     | publisher | Created   | watcher, creator, publisher | able       | published  |
  #
  # Scenario Outline: Modifying a Business Concept and seeing the old version
  #   Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain with <status> status with the following data:
  #     | Description |
  #     | First version of saldo medio |
  #   When <user> tries to modify a business concept with the name "Saldo medio" in the "Saldos" domain using following data:
  #     | Description |
  #     | Second version of saldo medio |
  #   Then the system returns a result with code <result>
  #   And the user list <users> is <able> to see the business concept "Saldo Medio" in <new_status> status with Following Data:
  #     | Description |
  #     | First version of saldo medio |
  #
  #   Examples:
  #     | user      | status         | result    | users                       | able       | new_status |
  #     | watcher   | draft          | Forbidden | watcher                     | not able   | draft      |
  #     | watcher   | draft          | Forbidden | creator, publisher          | able       | draft      |
  #     | creator   | draft          | Ok        | watcher, creator, publisher | not able   | draft      |
  #     | publisher | draft          | Ok        | watcher, creator, publisher | not able   | draft      |
  #     | watcher   | published      | Forbidden | watcher, creator, publisher | not able   | draft      |
  #     | creator   | published      | Ok        | watcher, creator, publisher | not able   | draft      |
  #     | publisher | published      | Ok        | watcher, creator, publisher | not able   | draft      |
  #     | watcher   | published      | Forbidden | watcher, creator, publisher | able       | published  |
  #     | creator   | published      | Ok        | watcher, creator, publisher | able       | published  |
  #     | publisher | published      | Ok        | watcher, creator, publisher | able       | published  |
  #
  # Scenario Outline: Modifying a Business Concept and seeing the new draft version
  #   Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain with <status> status with the following data:
  #     | Description |
  #     | First version of saldo medio |
  #   When <user> tries to modify a business concept with the name "Saldo medio" in the "Saldos" domain using following data:
  #     | Description |
  #     | Second version of saldo medio |
  #   Then the system returns a result with code <result>
  #   And the user list <users> is <able> to see the business concept "Saldo Medio" in <new_status> status with Following Data:
  #     | Description |
  #     | Second version of saldo medio |
  #
  #   Examples:
  #     | user      | status         | result    | users                       | able       | new_status |
  #     | watcher   | draft          | Forbidden | watcher                     | not able   | draft      |
  #     | watcher   | draft          | Forbidden | creator, publisher          | able       | draft      |
  #     | creator   | draft          | Ok        | watcher, creator, publisher | able       | draft      |
  #     | publisher | draft          | Ok        | watcher, creator, publisher | able       | draft      |
  #     | watcher   | published      | Forbidden | watcher, creator, publisher | not able   | draft      |
  #     | creator   | published      | Ok        | watcher, creator, publisher | able       | draft      |
  #     | publisher | published      | Ok        | watcher, creator, publisher | able       | draft      |
  #     | watcher   | published      | Forbidden | watcher, creator, publisher | not able   | published  |
  #     | creator   | published      | Ok        | watcher, creator, publisher | not able   | published  |
  #     | publisher | published      | Ok        | watcher, creator, publisher | not able   | published  |
  #
  # Scenario Outline: Depecrating a Business Concept
  #   Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain with <status> status
  #   When <user> tries to deprecate a business concept with the name "Saldo medio" in the "Saldos" domain
  #   Then the system returns a result with code <result>
  #   And the user list <users> is <able> to see the business concept "Saldo Medio" in <new_status> status
  #
  #   Examples:
  #     | user      | status         | result    | users                       | able       | new_status |
  #     | watcher   | draft          | Forbidden | watcher, creator, publisher | not able   | deprecated |
  #     | watcher   | draft          | Forbidden | watcher                     | not able   | draft      |
  #     | watcher   | draft          | Forbidden | creator, publisher          | able       | draft      |
  #     | creator   | draft          | Forbidden | watcher, creator, publisher | not able   | deprecated |
  #     | creator   | draft          | Forbidden | watcher                     | not able   | draft      |
  #     | creator   | draft          | Forbidden | creator, publisher          | able       | draft      |
  #     | publisher | draft          | Ok        | watcher, creator, publisher | not able   | draft      |
  #     | publisher | draft          | Ok        | watcher, creator, publisher | able       | deprecated |
  #     | watcher   | published      | Forbidden | watcher, creator, publisher | not able   | deprecated |
  #     | watcher   | published      | Forbidden | watcher, creator, publisher | able       | published  |
  #     | creator   | published      | Forbidden | watcher, creator, publisher | not able   | deprecated |
  #     | creator   | published      | Forbidden | watcher, creator, publisher | able       | published  |
  #     | publisher | published      | Ok        | watcher, creator, publisher | not able   | published  |
  #     | publisher | published      | Ok        | watcher, creator, publisher | able       | deprecated |
