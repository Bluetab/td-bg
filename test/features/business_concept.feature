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
      | Last User         | app-admin                                                                |
      | Version           | 1                                                                        |

  Scenario: Create a business concept with dinamic data
    Given an existing Domain Group called "My Parent Group"
    And an existing Domain Group called "My Child Group" child of Domain Group "My Parent Group"
    And an existing Data Domain called "My Domain" child of Domain Group "My Child Group"
    And an existing Business Concept type called "Business Term" with following definition:
     | Field            | Format        | Max Size | Values                                        | Mandatory | Default Value |
     | Formula          | string        | 100      |                                               |    NO     |               |
     | Format           | list          |          | Date, Numeric, Amount, Text                   |    YES    |               |
     | List of Values   | variable_list | 100      |                                               |    NO     |               |
     | Sensitive Data   | list          |          | N/A, Personal Data, Related to personal Data  |    NO     | N/A           |
     | Update Frequence | list          |          | Not defined, Daily, Weekly, Monthly, Yearly   |    NO     | Not defined   |
     | Related Area     | string        | 100      |                                               |    NO     |               |
     | Default Value    | string        | 100      |                                               |    NO     |               |
     | Additional Data  | string        | 500      |                                               |    NO     |               |
    When "app-admin" tries to create a business concept in the Data Domain "My Domain" with following data:
      | Field             | Value                                                                    |
      | Type              | Business Term                                                            |
      | Name              | My Dinamic Business Term                                                 |
      | Description       | This is the first description of my business term which is a date        |
      | Formula           |                                                                          |
      | Format            | Date                                                                     |
      | List of Values    |                                                                          |
      | Related Area      |                                                                          |
      | Default Value     |                                                                          |
      | Additional Data   |                                                                          |
    Then the system returns a result with code "Created"
    And "app-admin" is able to view business concept "My Dinamic Business Term" as a child of Data Domain "My Domain" with following data:
      | Field             | Value                                                              |
      | Name              | My Dinamic Business Term                                           |
      | Type              | Business Term                                                      |
      | Description       | This is the first description of my business term which is a date  |
      | Formula           |                                                                    |
      | Format            | Date                                                               |
      | List of Values    |                                                                    |
      | Sensitive Data    | N/A                                                                |
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
    | List of Values   | variable_list | 100      |                                              |    NO     |               |
    | Sensitive Data    | list         |          | N/A, Personal Data, Related to personal Data |    NO     | N/A           |
    | Update Frequence | list          |          | Not defined, Daily, Weekly, Monthly, Yearly  |    NO     | Not defined   |
    | Related Area     | string        | 100      |                                              |    NO     |               |
    | Default Value    | string        | 100      |                                              |    NO     |               |
    | Additional Data  | string        | 500      |                                              |    NO     |               |
   And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
     | Field             | Value                                                                    |
     | Type              | Business Term                                                            |
     | Name              | My Date Business Term                                                    |
     | Description       | This is the first description of my business term which is a date        |
     | Formula           |                                                                          |
     | Format            | Date                                                                     |
     | List of Values    |                                                                          |
     | Sensitive Data    | N/A                                                                      |
     | Update Frequence  | Not defined                                                              |
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
   And if result <result> is "Ok", user <user> is able to view business concept "My Date Business Term" of type "Business Term" with following data:
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
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                                              |
      | Type              | Business Term                                                      |
      | Name              | My Date Business Term                                              |
      | Description       | This is the first description of my business term which is a date  |
    When "<user>" tries to send for approval a business concept with name "My Date Business Term" of type "Business Term"
    Then the system returns a result with code "<result>"
    And if result <result> is "Ok", user <user> is able to view business concept "My Date Business Term" of type "Business Term" with following data:
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
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                                              |
      | Type              | Business Term                                                      |
      | Name              | My Business Term                                                   |
      | Description       | This is the first description of my business term which is a date  |
    And the status of business concept with name "My Business Term" of type "Business Term" is set to "pending_approval"
    When <user> tries to publish a business concept with name "My Business Term" of type "Business Term"
    Then the system returns a result with code "<result>"
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business Term" with following data:
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

  Scenario Outline: Reject existing Business Concept in Pending Approval status
    Given an existing Domain Group called "My Parent Group"
    And an existing Domain Group called "My Child Group" child of Domain Group "My Parent Group"
    And an existing Data Domain called "My Domain" child of Domain Group "My Child Group"
    And following users exist with the indicated role in Data Domain "My Domain"
      | user      | role    |
      | creator   | create  |
      | watcher   | watch   |
      | publisher | publish |
      | admin     | admin   |
    And an existing Business Concept type called "Business Term" with empty definition
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                             |
      | Type              | Business Term                                     |
      | Name              | My Business Term                                  |
      | Description       | This is the first description of my business term |
    And the status of business concept with name "My Business Term" of type "Business Term" is set to "pending_approval"
    When <user> tries to reject a business concept with name "My Business Term" of type "Business Term" and reject reason "Description is not accurate"
    Then the system returns a result with code "<result>"
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business Term" with following data:
     | Field             | Value                                                              |
     | Name              | My Business Term                                                   |
     | Type              | Business Term                                                      |
     | Description       | This is the first description of my business term                  |
     | Last Modification | Some timestamp                                                     |
     | Last User         | app-admin                                                          |
     | Version           | 1                                                                  |
     | Status            | rejected                                                           |
     | Reject Reason     | Description is not accurate                                        |

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
      | Last User         | app-admin                                                               |
      | Version           | 1                                                                       |
    And "app-admin" is not able to view business concept "My Business Term" as a child of Data Domain "My Second Domain"

  Scenario Outline: Modification of existing Business Concept in Published status
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
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                             |
      | Type              | Business Term                                     |
      | Name              | My Business Term                                  |
      | Description       | This is the first description of my business term |
    And the status of business concept with name "My Business Term" of type "Business Term" is set to "published"
    When <user> tries to modify a business concept "My Business Term" of type "Business Term" with following data:
      | Field                 | Value                                              |
      | Type                  | Business Term                                      |
      | Name                  | My Business Term                                   |
      | Description           | This is the second description of my business term |
      | Modification Comments | Modification on the Business Term description      |
    Then the system returns a result with code "<result>"
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business Term" and version "1" with following data:
      | Field                 | Value                                              |
      | Type                  | Business Term                                      |
      | Name                  | My Business Term                                   |
      | Description           | This is the first description of my business term  |
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business Term" and version "2" with following data:
      | Field                 | Value                                              |
      | Type                  | Business Term                                      |
      | Name                  | My Business Term                                   |
      | Description           | This is the second description of my business term |
      | Modification Comments | Modification on the Business Term description      |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Created      |
      | publisher | Created      |
      | admin     | Created      |

  Scenario Outline: Delete existing Business Concept in Draft Status
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
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                             |
      | Type              | Business Term                                     |
      | Name              | My Business Term                                  |
      | Description       | This is the first description of my business term |
    And the status of business concept with name "My Business Term" of type "Business Term" is set to "draft"
    When <user> tries to delete a business concept "My Business Term" of type "Business Term"
    Then the system returns a result with code "<result>"
    And if result <result> is "Deleted", user <user> is not able to view business concept "My Business Term" of type "Business Term"
    And if result <result> is not "Deleted", user <user> is able to view business concept "My Business Term" of type "Business Term" and version "1" with following data:
      | Field                 | Value                                              |
      | Type                  | Business Term                                      |
      | Name                  | My Business Term                                   |
      | Description           | This is the first description of my business term  |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Deleted      |
      | publisher | Deleted      |
      | admin     | Deleted      |


  Scenario Outline: Publish a second version of a Business Concept
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
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                             |
      | Type              | Business Term                                     |
      | Name              | My Business Term                                  |
      | Description       | This is the first description of my business term |
    And the status of business concept with name "My Business Term" of type "Business Term" is set to "published"
    And business concept with name "My Business Term" of type "Business Term" has been modified with following data:
      | Field                 | Value                                              |
      | Type                  | Business Term                                      |
      | Name                  | My Business Term                                   |
      | Description           | This is the second description of my business term |
      | Modification Comments | Modification on the Business Term description      |
    And the status of business concept with name "My Business Term" of type "Business Term" is set to "pending_approval"
    When <user> tries to publish a business concept with name "My Business Term" of type "Business Term"
    Then the system returns a result with code "<result>"
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business Term" and version "2" with following data:
      | Field             | Value                                                              |
      | Name              | My Business Term                                                   |
      | Type              | Business Term                                                      |
      | Description       | This is the second description of my business term                 |
      | Last Modification | Some timestamp                                                     |
      | Last User         | <user>                                                             |
      | Version           | 2                                                                  |
      | Status            | published                                                          |
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business Term" and version "1" with following data:
      | Field             | Value                                                              |
      | Name              | My Business Term                                                   |
      | Type              | Business Term                                                      |
      | Description       | This is the first description of my business term                 |
      | Last Modification | Some timestamp                                                     |
      | Last User         | <user>                                                             |
      | Version           | 1                                                                  |
      | Status            | versioned                                                          |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Ok           |
      | admin     | Ok           |

  Scenario Outline: Modify a second version of a published Business Concept
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
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                             |
      | Type              | Business Term                                     |
      | Name              | My Business Term                                  |
      | Description       | This is the first description of my business term |
    And the status of business concept with name "My Business Term" of type "Business Term" is set to "published" for version 2
    When <user> tries to modify a business concept "My Business Term" of type "Business Term" with following data:
      | Field                 | Value                                               |
      | Type                  | Business Term                                       |
      | Name                  | My Business Term                                    |
      | Description           | This is the third description of my business term   |
      | Modification Comments | Third Modification on the Business Term description |
    Then the system returns a result with code "<result>"
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business Term" and version "2" with following data:
      | Field                 | Value                                              |
      | Type                  | Business Term                                      |
      | Name                  | My Business Term                                   |
      | Description           | This is the first description of my business term  |
      | Status                | published                                          |
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business Term" and version "3" with following data:
      | Field                 | Value                                               |
      | Type                  | Business Term                                       |
      | Name                  | My Business Term                                    |
      | Description           | This is the third description of my business term   |
      | Modification Comments | Third Modification on the Business Term description |
      | Status                | draft                                               |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Created      |
      | publisher | Created      |
      | admin     | Created      |

  Scenario Outline: Delete existing Business Concept in Reject Status
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
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                             |
      | Type              | Business Term                                     |subebuine
      | Name              | My Business Term                                  |
      | Description       | This is the first description of my business term |
    And the status of business concept with name "My Business Term" of type "Business Term" is set to "rejected"
    When <user> tries to delete a business concept "My Business Term" of type "Business Term"
    Then the system returns a result with code "<result>"
    And if result <result> is "Deleted", user <user> is not able to view business concept "My Business Term" of type "Business Term"
    And if result <result> is not "Deleted", user <user> is able to view business concept "My Business Term" of type "Business Term" and version "1" with following data:
      | Field                 | Value                                              |
      | Type                  | Business Term                                      |
      | Name                  | My Business Term                                   |
      | Description           | This is the first description of my business term  |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Deleted      |
      | publisher | Deleted      |
      | admin     | Deleted      |


  Scenario Outline: Modification of existing Business Concept in Reject status
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
   And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
     | Field             | Value                                             |
     | Type              | Business Term                                     |
     | Name              | My Business Term                                  |
     | Description       | This is the first description of my business term |
   And the status of business concept with name "My Business Term" of type "Business Term" is set to "rejected"
   When <user> tries to modify a business concept "My Business Term" of type "Business Term" with following data:
     | Field             | Value                                                                    |
     | Type              | Business Term                                                            |
     | Name              | My Date Business Term                                                    |
     | Description       | This is the second description of my business term                       |
   Then the system returns a result with code "<result>"
   And if result <result> is "Ok", user <user> is able to view business concept "My Date Business Term" of type "Business Term" with following data:
    | Field             | Value                                              |
    | Name              | My Date Business Term                              |
    | Type              | Business Term                                      |
    | Description       | This is the second description of my business term |
    | Last Modification | Some timestamp                                     |
    | Last User         | app-admin                                          |
    | Version           | 1                                                  |
    | Status            | draft                                              |

   Examples:
     | user      | result       |
    #  | watcher   | Unauthorized |
    #  | creator   | Ok           |
    #  | publisher | Ok           |
     | admin     | Ok           |

  Scenario Outline: Sending Business Concept in Reject Status for approval
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
   And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
     | Field             | Value                                             |
     | Type              | Business Term                                     |
     | Name              | My Business Term                                  |
     | Description       | This is the first description of my business term |
   And the status of business concept with name "My Business Term" of type "Business Term" is set to "rejected"
   When "<user>" tries to send for approval a business concept with name "My Business Term" of type "Business Term"
   Then the system returns a result with code "<result>"
   And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business Term" with following data:
    | Field             | Value                                              |
    | Name              | My Business Term                                   |
    | Type              | Business Term                                      |
    | Description       | This is the first description of my business term  |
    | Last Modification | Some timestamp                                     |
    | Last User         | app-admin                                          |
    | Version           | 1                                                  |
    | Status            | pending_approval                                   |

   Examples:
     | user      | result       |
     | watcher   | Unauthorized |
     | creator   | Ok           |
     | publisher | Ok           |
     | admin     | Ok           |

  Scenario Outline: Delete current draft version for a BC that has been published previously
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
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                             |
      | Type              | Business Term                                     |
      | Name              | My Business Term                                  |
      | Description       | This is the first description of my business term |
    And the status of business concept with name "My Business Term" of type "Business Term" is set to "draft" for version 2
    When <user> tries to delete a business concept "My Business Term" of type "Business Term"
    Then the system returns a result with code "<result>"
    And user <user> is able to view business concept "My Business Term" of type "Business Term" and version "1" with following data:
      | Field             | Value                                                              |
      | Name              | My Business Term                                                   |
      | Type              | Business Term                                                      |
      | Description       | This is the first description of my business term                  |
      | Last Modification | Some timestamp                                                     |
      | Last User         | app-admin                                                          |
      | Version           | 1                                                                  |
      | Status            | published                                                          |
    And if result <result> is "Deleted",  business concept "My Business Term" of type "Business Term" and version "2" does not exist

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Deleted      |
      | publisher | Deleted      |
      | admin     | Deleted      |

  Scenario Outline: Modify a Draft version of a BC previously published
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
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                             |
      | Type              | Business Term                                     |
      | Name              | My Business Term                                  |
      | Description       | This is the first description of my business term |
    And the status of business concept with name "My Business Term" of type "Business Term" is set to "draft" for version 2
    When <user> tries to modify a business concept "My Business Term" of type "Business Term" with following data:
      | Field                 | Value                                              |
      | Type                  | Business Term                                      |
      | Name                  | My Business Term                                   |
      | Description           | This is the second description of my business term |
      | Modification Comments | Modification on the Business Term description      |
    Then the system returns a result with code "<result>"
    And user <user> is able to view business concept "My Business Term" of type "Business Term" and version "1" with following data:
      | Field             | Value                                                              |
      | Name              | My Business Term                                                   |
      | Type              | Business Term                                                      |
      | Description       | This is the first description of my business term                  |
      | Last Modification | Some timestamp                                                     |
      | Last User         | app-admin                                                          |
      | Version           | 1                                                                  |
      | Status            | published                                                          |
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business Term" and version "2" with following data:
      | Field                 | Value                                                              |
      | Name                  | My Business Term                                                   |
      | Type                  | Business Term                                                      |
      | Description           | This is the second description of my business term                 |
      | Modification Comments | Modification on the Business Term description                      |
      | Last Modification     | Some timestamp                                                     |
      | Last User             | app-admin                                                          |
      | Version               | 2                                                                  |
      | Status                | draft                                                              |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Ok           |
      | publisher | Ok           |
      | admin     | Ok           |

  Scenario Outline: Send for Approval a draft version of a BC previously published
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
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                             |
      | Type              | Business Term                                     |
      | Name              | My Business Term                                  |
      | Description       | This is the first description of my business term |
    And the status of business concept with name "My Business Term" of type "Business Term" is set to "draft" for version 2
    When "<user>" tries to send for approval a business concept with name "My Business Term" of type "Business Term"
    Then the system returns a result with code "<result>"
    And user <user> is able to view business concept "My Business Term" of type "Business Term" and version "1" with following data:
      | Field             | Value                                                              |
      | Name              | My Business Term                                                   |
      | Type              | Business Term                                                      |
      | Description       | This is the first description of my business term                  |
      | Last Modification | Some timestamp                                                     |
      | Last User         | app-admin                                                          |
      | Version           | 1                                                                  |
      | Status            | published                                                          |
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business Term" and version "2" with following data:
      | Field                 | Value                                                              |
      | Name                  | My Business Term                                                   |
      | Type                  | Business Term                                                      |
      | Description           | This is the first description of my business term                  |
      | Last Modification     | Some timestamp                                                     |
      | Last User             | app-admin                                                          |
      | Version               | 2                                                                  |
      | Status                | pending_approval                                                   |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Ok           |
      | publisher | Ok           |
      | admin     | Ok           |

  Scenario Outline: Send for Approval a rejected version of a BC prevously published
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
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                             |
      | Type              | Business Term                                     |
      | Name              | My Business Term                                  |
      | Description       | This is the first description of my business term |
    And the status of business concept with name "My Business Term" of type "Business Term" is set to "rejected" for version 2
    When "<user>" tries to send for approval a business concept with name "My Business Term" of type "Business Term"
    Then the system returns a result with code "<result>"
    And user <user> is able to view business concept "My Business Term" of type "Business Term" and version "1" with following data:
      | Field             | Value                                                              |
      | Name              | My Business Term                                                   |
      | Type              | Business Term                                                      |
      | Description       | This is the first description of my business term                  |
      | Last Modification | Some timestamp                                                     |
      | Last User         | app-admin                                                          |
      | Version           | 1                                                                  |
      | Status            | published                                                          |
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business Term" and version "2" with following data:
      | Field                 | Value                                                              |
      | Name                  | My Business Term                                                   |
      | Type                  | Business Term                                                      |
      | Description           | This is the first description of my business term                  |
      | Last Modification     | Some timestamp                                                     |
      | Last User             | app-admin                                                          |
      | Version               | 2                                                                  |
      | Status                | pending_approval                                                   |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Ok           |
      | publisher | Ok           |
      | admin     | Ok           |

  Scenario Outline: Reject a pending approval BC that has previously been published
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
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                             |
      | Type              | Business Term                                     |
      | Name              | My Business Term                                  |
      | Description       | This is the first description of my business term |
    And the status of business concept with name "My Business Term" of type "Business Term" is set to "pending_approval" for version 2
    When <user> tries to reject a business concept with name "My Business Term" of type "Business Term" and reject reason "Description is not accurate"
    Then the system returns a result with code "<result>"
    And user <user> is able to view business concept "My Business Term" of type "Business Term" and version "1" with following data:
      | Field             | Value                                                              |
      | Name              | My Business Term                                                   |
      | Type              | Business Term                                                      |
      | Description       | This is the first description of my business term                  |
      | Last Modification | Some timestamp                                                     |
      | Last User         | app-admin                                                          |
      | Version           | 1                                                                  |
      | Status            | published                                                          |
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business Term" and version "2" with following data:
      | Field                 | Value                                                              |
      | Name                  | My Business Term                                                   |
      | Type                  | Business Term                                                      |
      | Description           | This is the first description of my business term                  |
      | Last Modification     | Some timestamp                                                     |
      | Last User             | app-admin                                                          |
      | Version               | 2                                                                  |
      | Status                | rejected                                                           |
      | Reject Reason         | Description is not accurate                                        |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Ok           |
      | admin     | Ok           |

  Scenario Outline: Deprecation of existing Business Concept in Published status
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
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                             |
      | Type              | Business Term                                     |
      | Name              | My Business Term                                  |
      | Description       | This is the first description of my business term |
    And the status of business concept with name "My Business Term" of type "Business Term" is set to "published"
    When <user> tries to deprecate a business concept "My Business Term" of type "Business Term"
    Then the system returns a result with code "<result>"
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business Term" and version "1" with following data:
      | Field                 | Value                                              |
      | Type                  | Business Term                                      |
      | Name                  | My Business Term                                   |
      | Description           | This is the first description of my business term  |
      | Status                | deprecated                                         |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Ok           |
      | admin     | Ok           |

  Scenario Outline: Deprecate a BC that has a second version published
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
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                             |
      | Type              | Business Term                                     |
      | Name              | My Business Term                                  |
      | Description       | This is the first description of my business term |
    And the status of business concept with name "My Business Term" of type "Business Term" is set to "published" for version 2
    When <user> tries to deprecate a business concept "My Business Term" of type "Business Term"
    Then the system returns a result with code "<result>"
    And user <user> is able to view business concept "My Business Term" of type "Business Term" and version "1" with following data:
      | Field             | Value                                                              |
      | Name              | My Business Term                                                   |
      | Type              | Business Term                                                      |
      | Description       | This is the first description of my business term                  |
      | Last Modification | Some timestamp                                                     |
      | Last User         | app-admin                                                          |
      | Version           | 1                                                                  |
      | Status            | versioned                                                          |
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business Term" and version "2" with following data:
      | Field                 | Value                                                              |
      | Name                  | My Business Term                                                   |
      | Type                  | Business Term                                                      |
      | Description           | This is the first description of my business term                  |
      | Last Modification     | Some timestamp                                                     |
      | Last User             | app-admin                                                          |
      | Version               | 2                                                                  |
      | Status                | deprecated                                                         |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Ok           |
      | admin     | Ok           |

  Scenario Outline: History of changes in Business Glossary
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
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                             |
      | Type              | Business Term                                     |
      | Name              | My Business Term                                  |
      | Description       | This is the first description of my business term |
    And the status of business concept with name "My Business Term" of type "Business Term" is set to "pending_approval" for version 4
    When <user> tries to query history for a business concept with name "My Business Term" of type "Business Term"
    Then if <user> is "watcher" the system returns following data:
      | name             | type          | description                                        | Last Modification | Last User   | version | status           |
      | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 3       | published        |
      | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 2       | versioned        |
      | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 1       | versioned        |
    Then if <user> is "creator" the system returns following data:
      | name             | type          | description                                        | Last Modification | Last User   | version | status           |
      | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 3       | published        |
      | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 2       | versioned        |
      | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 1       | versioned        |
    Then if <user> is "publisher" the system returns following data:
      | name             | type          | description                                        | Last Modification | Last User   | version | status           |
      | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 4       | pending_approval |
      | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 3       | published        |
      | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 2       | versioned        |
      | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 1       | versioned        |
    Then if <user> is "admin" the system returns following data:
      | name             | type          | description                                        | Last Modification | Last User   | version | status           |
      | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 4       | pending_approval |
      | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 3       | published        |
      | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 2       | versioned        |
      | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 1       | versioned        |

    Examples:
      | user      |
      | watcher   |
      | creator   |
      | publisher |
      | admin     |

  Scenario Outline: Create a alias for a business concept
    Given an existing Domain Group called "My Group"
    And an existing Data Domain called "My Domain" child of Domain Group "My Group"
    And following users exist with the indicated role in Data Domain "My Domain"
      | user      | role    |
      | watcher   | watch   |
      | creator   | create  |
      | publisher | publish |
      | admin     | admin   |
    And an existing Business Concept type called "Business Term" with empty definition
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                             |
      | Type              | Business Term                                     |
      | Name              | My Business Term                                  |
      | Description       | This is the first description of my business term |
  When <user> tries to create a new alias "My Synonym Term" for business concept with name "My Business Term" of type "Business Term"
  Then the system returns a result with code "<result>"
  And if <result> is "Created", user <user> is able to see following list of aliases for business concept with name "My Business Term" of type "Business Term"
      | name           |
      | My Synonym Term |

  Examples:
    | user      | result       |
    | watcher   | Unauthorized |
    | creator   | Unauthorized |
    | publisher | Created      |
    | admin     | Created      |

  Scenario Outline: Delete alias for a business concept
    Given an existing Domain Group called "My Group"
    And an existing Data Domain called "My Domain" child of Domain Group "My Group"
    And following users exist with the indicated role in Data Domain "My Domain"
      | user      | role    |
      | watcher   | watch   |
      | creator   | create  |
      | publisher | publish |
      | admin     | admin   |
    And an existing Business Concept type called "Business Term" with empty definition
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                             |
      | Type              | Business Term                                     |
      | Name              | My Business Term                                  |
      | Description       | This is the first description of my business term |
    And business concept with name "My Business Term" of type "Business Term" has an alias "My Synonym Term"
    And business concept with name "My Business Term" of type "Business Term" has an alias "My Second Synonym Term"
    When <user> tries to delete alias "My Synonym Term" for business concept with name "My Business Term" of type "Business Term"
    Then the system returns a result with code "<result>"
    And if <result> is "Deleted", user <user> is able to see following list of aliases for business concept with name "My Business Term" of type "Business Term"
        | name                  |
        | My Second Synonym Term |
    And if <result> is not "Deleted", user <user> is able to see following list of aliases for business concept with name "My Business Term" of type "Business Term"
        | name                  |
        | My Synonym Term        |
        | My Second Synonym Term |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Deleted      |
      | admin     | Deleted      |

  # Scenario: User should not be able to create a business concept with same type and name as an existing alias
  #   Given an existing Domain Group called "My Parent Group"
  #   And an existing Data Domain called "My Domain" child of Domain Group "My Parent Group"
  #   And an existing Business Concept type called "Business Term" with empty definition
  #   And an existing Business Concept in the Data Domain "My Domain" with following data:
  #    | Field             | Value                                                                   |
  #    | Type              | Business Term                                                           |
  #    | Name              | My Business Term                                                        |
  #    | Aliases           | Alias, Second Alias                                                     |
  #    | Description       | This is the first description of my business term which is very simple  |
  #   And business concept with name "My Business Term" of type "Business Term" has an alias "My Synonym Term"
  #   And an existing Domain Group called "My Second Parent Group"
  #   And an existing Data Domain called "My Second Domain" child of Domain Group "My Second Parent Group"
  #   When "app-admin" tries to create a business concept in the Data Domain "My Second Domain" with following data:
  #    | Field             | Value                                                                   |
  #    | Type              | Business Term                                                           |
  #    | Name              | My Synonym Term                                                         |
  #    | Description       | This is the second description of my business term                      |
  #   Then the system returns a result with code "Unprocessable Entity"
  #   And "app-admin" is not able to view business concept "My Synonym Term" as a child of Data Domain "My Second Domain"

  # Scenario: User should not be able to create an alias with same type and name as an existing business concept
  #   Given an existing Domain Group called "My Parent Group"
  #   And an existing Data Domain called "My Domain" child of Domain Group "My Parent Group"
  #   And an existing Business Concept type called "Business Term" with empty definition
  #   And an existing Business Concept in the Data Domain "My Domain" with following data:
  #    | Field             | Value                                                                   |
  #    | Type              | Business Term                                                           |
  #    | Name              | My Business Term                                                        |
  #    | Description       | This is the first description of my business term which is very simple  |
  #   And an existing Domain Group called "My Second Parent Group"
  #   And an existing Data Domain called "My Second Domain" child of Domain Group "My Second Parent Group"
  #   And an existing Business Concept in the Data Domain "My Domain" with following data:
  #    | Field             | Value                                                                          |
  #    | Type              | Business Term                                                                  |
  #    | Name              | Second Business Term                                                           |
  #    | Description       | This is the first description of my second business term which is very simple  |
  #   When "app-admin" tries to create a new alias "Second Business Term" for business concept with name "My Business Term" of type "Business Term"                  |
  #   Then the system returns a result with code "Unprocessable Entity"
  #   And user "app-admin" is able to see following list of aliases for business concept with name "My Business Term" of type "Business Term"
  #     | Alias           |
