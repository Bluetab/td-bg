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
     | Sensitive Data    | list          |          | N/A, Personal Data, Related to personal Data |    NO     | N/A           |
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
      #| Sensitive Data     | N/A                                                                |
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
      | Sensitive Data     | N/A                                                                |
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
   And an existing Business Concept type called "Business Term" with following definition:
    | Field            | Format        | Max Size | Values                                       | Mandatory | Default Value |
    | Formula          | string        | 100      |                                              |    NO     |               |
    | Format           | list          |          | Date, Numeric, Amount, Text                  |    YES    |               |
    | List of Values   | variable list | 100      |                                              |    NO     |               |
    | Sensitive Data    | list         |          | N/A, Personal Data, Related to personal Data |    NO     | N/A           |
    | Update Frequence | list          |          | Not defined, Daily, Weekly, Monthly, Yearly  |    NO     | Not defined   |
    | Related Area     | string        | 100      |                                              |    NO     |               |
    | Default Value    | string        | 100      |                                              |    NO     |               |
    | Additional Data  | string        | 500      |                                              |    NO     |               |
   And user "<user>" is logged in the application with password "<user>"
   And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
     | Field             | Value                                                                    |
     | Type              | Business Term                                                            |
     | Name              | My Date Business Term                                                    |
     | Description       | This is the first description of my business term which is a date        |
     | Formula           |                                                                          |
     | Format            | Date                                                                     |
     | List of Values    |                                                                          |
     #| Sensitive Data    | N/A                                                                     |
     #| Update Frequence  | Not defined                                                             |
     | Related Area      |                                                                          |
     | Default Value     |                                                                          |
     | Additional Data   |                                                                          |
   When <user> tries to modify a business concept "My Date Business Term" of type "Business Term" with following data:
     | Field             | Value                                                                    |
     | Type              | Business Term                                                            |
     | Name              | My Date Business Term                                                    |
     | Description       | This is the second description of my business term which is a date       |
     | Format            | Date                                                                     |
     | Sensitive Data    | Related to personal Data                                                 |
     | Update Frequence  | Monthly                                                                  |

   Then the system returns a result with code "<result>"
   And if result <result> is "Ok", user <user> is able to view business concept "My Date Business Term" of type "Business Term" with follwing data:
    | Field             | Value                                                              |
    | Name              | My Date Business Term                                              |
    | Type              | Business Term                                                      |
    | Description       | This is the second description of my business term which is a date |
    | Formula           |                                                                    |
    | Format            | Date                                                               |
    | List of Values    |                                                                    |
    | Sensitive Data    | Related to personal Data                                           |
    | Update Frequence  | Monthly                                                            |
    | Related Area      |                                                                    |
    | Default Value     |                                                                    |
    | Additional Data   |                                                                    |
    | Last Modification | Some timestamp                                                     |
    | Last User         | app-admin                                                          |
    | Version           | 1                                                                  |
    | Status            | draft                                                              |

   Examples:
     | user      | result       |
     | watcher   | Unauthorized |
     | creator   | Ok           |
     | publisher | Ok           |
     | admin     | Ok           |

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
    And an existing Business Concept type called "Business Term" with empty definition
    And user "<user>" is logged in the application with password "<user>"
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                                              |
      | Type              | Business Term                                                      |
      | Name              | My Date Business Term                                              |
      | Description       | This is the first description of my business term which is a date  |
    When "<user>" tries to send for approval a business concept with name "My Date Business Term" of type "Business Term"
    Then the system returns a result with code "<result>"
    And if result <result> is "Ok", user <user> is able to view business concept "My Date Business Term" of type "Business Term" with follwing data:
     | Field             | Value                                                              |
     | Name              | My Date Business Term                                              |
     | Type              | Business Term                                                      |
     | Description       | This is the first description of my business term which is a date  |
     | Last Modification | Some timestamp                                                     |
     | Last User         | app-admin                                                          |
     | Version           | 1                                                                  |
     | Status            | pending_approval                                                   |
    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Ok           |
      | publisher | Ok           |
      | admin     | Ok           |

  Scenario Outline: Publish existing Business Concept in Pending Approval status
    Given an existing Domain Group called "My Parent Group"
    And an existing Domain Group called "My Child Group" child of Domain Group "My Parent Group"
    And an existing Data Domain called "My Domain" child of Domain Group "My Child Group"
    And following users exist with the indicated role in Data Domain "My Domain"
      | user      | role    |
      | watcher   | watch   |
      | creator   | create  |
      | publisher | publish |
      | admin     | admin   |
    And an existing Business Concept type called "Business Term" with empty definition
    And user "<user>" is logged in the application with password "<user>"
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                                              |
      | Type              | Business Term                                                      |
      | Name              | My Business Term                                                   |
      | Description       | This is the first description of my business term which is a date  |

    And the status of business concept with name "My Business Term" of type "Business Term" is set to "pending_approval"
    When <user> tries to publish a business concept with name "My Business Term" of type "Business Term"
    Then the system returns a result with code "<result>"
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business Term" with follwing data:
     | Field             | Value                                                              |
     | Name              | My Business Term                                                   |
     | Type              | Business Term                                                      |
     | Description       | This is the first description of my business term which is a date  |
     | Last Modification | Some timestamp                                                     |
     | Last User         | app-admin                                                          |
     | Version           | 1                                                                  |
     | Status            | published                                                          |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Ok           |
      | admin     | Ok           |


  Scenario: User should not be able to create a business concept with same type and name as an existing one
    Given an existing Domain Group called "My Parent Group"
    And an existing Data Domain called "My Domain" child of Domain Group "My Parent Group"
    And an existing Business Concept type called "Business Term" with empty definition
    And an existing Business Concept in the Data Domain "My Domain" with following data:
     | Field             | Value                                                                   |
     | Type              | Business Term                                                           |
     | Name              | My Business Term                                                        |
     | Description       | This is the first description of my business term which is very simple  |
    And an existing Domain Group called "My Second Parent Group"
    And an existing Data Domain called "My Second Domain" child of Domain Group "My Second Parent Group"
    And user "app-admin" is logged in the application with password "mypass"
    When "app-admin" tries to create a business concept in the Data Domain "My Second Domain" with following data:
     | Field             | Value                                                                   |
     | Type              | Business Term                                                           |
     | Name              | My Business Term                                                        |
     | Description       | This is the second description of my business term                      |
    Then the system returns a result with code "Unprocessable Entity"
    And "app-admin" is able to view business concept "My Business Term" as a child of Data Domain "My Domain" with following data:
      | Field             | Value                                                                   |
      | Type              | Business Term                                                           |
      | Name              | My Business Term                                                        |
      | Description       | This is the first description of my business term which is very simple  |
      | Status            | draft                                                                   |
      | Last Modification | Some Timestamp                                                          |
      | Last user         | app-admin                                                               |
      | Version           | 1                                                                       |
    And "app-admin" is not able to view business concept "My Business Term" as a child of Data Domain "My Second Domain"
