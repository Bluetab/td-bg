  Scenario Outline: Modification of existing Business Concept in Draft status
   Given an existing Domain called "My Parent Domain"
   And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
   And an existing Domain called "My Domain" child of Domain "My Child Domain"
   And following users exist with the indicated role in Domain "My Domain"
     | user      | role    |
     | watcher   | watch   |
     | creator   | create  |
     | publisher | publish |
     | admin     | admin   |
   And an existing Business Concept type called "Business_Term" with following definition:
    | Field            | Max Size | Values                                       | Cardinality | Default Value | Group      |
    | Formula          | 100      |                                              |    ?        |               | General    |
    | List of Values   | 100      |                                              |    ?        |               | Functional |
    | Sensitive Data   |          | N/A, Personal Data, Related to personal Data |    ?        | N/A           | Functional |
    | Update Frequence |          | Not defined, Daily, Weekly, Monthly, Yearly  |    ?        | Not defined   | General    |
    | Related Area     | 100      |                                              |    ?        |               | Functional |
    | Default Value    | 100      |                                              |    ?        |               | General    |
    | Additional Data  | 500      |                                              |    ?        |               | Functional |
   And an existing Business Concept of type "Business_Term" in the Domain "My Domain" with following data:
     | Field             | Value                                                                    |
     | Type              | Business_Term                                                            |
     | Name              | My Date Business Term                                                    |
     | Description       | This is the first description of my business term which is a date        |
     | Formula           |                                                                          |
     | List of Values    |                                                                          |
     | Sensitive Data    | N/A                                                                      |
     | Update Frequence  | Not defined                                                              |
     | Related Area      |                                                                          |
     | Default Value     |                                                                          |
     | Additional Data   |                                                                          |
   When "<user>" tries to modify a business concept "My Date Business Term" of type "Business_Term" with following data:
     | Field             | Value                                                                    |
     | Type              | Business_Term                                                            |
     | Name              | My Date Business Term                                                    |
     | Description       | This is the second description of my business term which is a date       |
     | Sensitive Data    | Related to personal Data                                                 |
     | Update Frequence  | Monthly                                                                  |
   Then the system returns a result with code "<result>"
   And if result <result> is "Ok", user <user> is able to view business concept "My Date Business Term" of type "Business_Term" with following data:
    | Field             | Value                                                              |
    | Name              | My Date Business Term                                              |
    | Type              | Business_Term                                                      |
    | Description       | This is the second description of my business term which is a date |
    | Formula           |                                                                    |
    | List of Values    |                                                                    |
    | Sensitive Data    | Related to personal Data                                           |
    | Update Frequence  | Monthly                                                            |
    | Related Area      |                                                                    |
    | Default Value     |                                                                    |
    | Additional Data   |                                                                    |
    | Last Modification | Some timestamp                                                     |
    | Last User         | app-admin                                                          |
    | Current           | true                                                               |
    | Version           | 1                                                                  |
    | Status            | draft                                                              |

   Examples:
     | user      | result       |
     | watcher   | Unauthorized |
     | creator   | Ok           |
     | publisher | Ok           |
     | admin     | Ok           |

  Scenario Outline: Modification of existing Business Concept in Published status
   Given an existing Domain called "My Parent Domain"
   And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
   And an existing Domain called "My Domain" child of Domain "My Child Domain"
   And following users exist with the indicated role in Domain "My Domain"
     | user      | role    |
     | watcher   | watch   |
     | creator   | create  |
     | publisher | publish |
     | admin     | admin   |
   And an existing Business Concept type called "Business_Term" with empty definition
   And an existing Business Concept of type "Business_Term" in the Domain "My Domain" with following data:
     | Field             | Value                                             |
     | Type              | Business_Term                                     |
     | Name              | My Business Term                                  |
     | Description       | This is the first description of my business term |
   And the status of business concept with name "My Business Term" of type "Business_Term" is set to "published"
   When "<user>" tries to modify a business concept "My Business Term" of type "Business_Term" with following data:
     | Field                 | Value                                              |
     | Type                  | Business_Term                                      |
     | Name                  | My Business Term                                   |
     | Description           | This is the second description of my business term |
     | Modification Comments | Modification on the Business Term description      |
   Then the system returns a result with code "<result>"
   And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business_Term" and version "1" with following data:
     | Field                 | Value                                              |
     | Type                  | Business_Term                                      |
     | Name                  | My Business Term                                   |
     | Description           | This is the first description of my business term  |
   And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business_Term" and version "2" with following data:
     | Field                 | Value                                              |
     | Type                  | Business_Term                                      |
     | Name                  | My Business Term                                   |
     | Description           | This is the second description of my business term |
     | Modification Comments | Modification on the Business Term description      |

   Examples:
     | user      | result       |
     | watcher   | Unauthorized |
     | creator   | Ok           |
     | publisher | Ok           |
     | admin     | Ok           |

   Scenario Outline: Modify a second version of a published Business Concept
     Given an existing Domain called "My Parent Domain"
     And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
     And an existing Domain called "My Domain" child of Domain "My Child Domain"
     And following users exist with the indicated role in Domain "My Domain"
       | user      | role    |
       | watcher   | watch   |
       | creator   | create  |
       | publisher | publish |
       | admin     | admin   |
     And an existing Business Concept type called "Business_Term" with empty definition
     And an existing Business Concept of type "Business_Term" in the Domain "My Domain" with following data:
       | Field             | Value                                             |
       | Type              | Business_Term                                     |
       | Name              | My Business Term                                  |
       | Description       | This is the first description of my business term |
     And the status of business concept with name "My Business Term" of type "Business_Term" is set to "published" for version 2
     When "<user>" tries to modify a business concept "My Business Term" of type "Business_Term" with following data:
       | Field                 | Value                                               |
       | Type                  | Business_Term                                       |
       | Name                  | My Business Term                                    |
       | Description           | This is the third description of my business term   |
       | Modification Comments | Third Modification on the Business Term description |
     Then the system returns a result with code "<result>"
     And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business_Term" and version "2" with following data:
       | Field                 | Value                                              |
       | Type                  | Business_Term                                      |
       | Name                  | My Business Term                                   |
       | Description           | This is the first description of my business term  |
       | Status                | published                                          |
     And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business_Term" and version "3" with following data:
       | Field                 | Value                                               |
       | Type                  | Business_Term                                       |
       | Name                  | My Business Term                                    |
       | Description           | This is the third description of my business term   |
       | Modification Comments | Third Modification on the Business Term description |
       | Status                | draft                                               |

     Examples:
       | user      | result       |
       | watcher   | Unauthorized |
       | creator   | Ok           |
       | publisher | Ok           |
       | admin     | Ok           |

   Scenario Outline: Modification of existing Business Concept in Reject status
    Given an existing Domain called "My Parent Domain"
    And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
    And an existing Domain called "My Domain" child of Domain "My Child Domain"
    And following users exist with the indicated role in Domain "My Domain"
      | user      | role    |
      | watcher   | watch   |
      | creator   | create  |
      | publisher | publish |
      | admin     | admin   |
    And an existing Business Concept type called "Business_Term" with empty definition
    And an existing Business Concept of type "Business_Term" in the Domain "My Domain" with following data:
      | Field             | Value                                             |
      | Type              | Business_Term                                     |
      | Name              | My Business Term                                  |
      | Description       | This is the first description of my business term |
    And the status of business concept with name "My Business Term" of type "Business_Term" is set to "rejected"
    When "<user>" tries to modify a business concept "My Business Term" of type "Business_Term" with following data:
      | Field             | Value                                                                    |
      | Type              | Business_Term                                                            |
      | Name              | My Date Business Term                                                    |
      | Description       | This is the second description of my business term                       |
    Then the system returns a result with code "<result>"
    And if result <result> is "Ok", user <user> is able to view business concept "My Date Business Term" of type "Business_Term" with following data:
     | Field             | Value                                              |
     | Name              | My Date Business Term                              |
     | Type              | Business_Term                                      |
     | Description       | This is the second description of my business term |
     | Last Modification | Some timestamp                                     |
     | Last User         | app-admin                                          |
     | Current           | true                                               |
     | Version           | 1                                                  |
     | Status            | draft                                              |

    Examples:
      | user      | result       |
     #  | watcher   | Unauthorized |
     #  | creator   | Ok           |
     #  | publisher | Ok           |
      | admin     | Ok           |

    Scenario Outline: Modify a Draft version of a BC previously published
      Given an existing Domain called "My Parent Domain"
      And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
      And an existing Domain called "My Domain" child of Domain "My Child Domain"
      And following users exist with the indicated role in Domain "My Domain"
        | user      | role    |
        | watcher   | watch   |
        | creator   | create  |
        | publisher | publish |
        | admin     | admin   |
      And an existing Business Concept type called "Business_Term" with empty definition
      And an existing Business Concept of type "Business_Term" in the Domain "My Domain" with following data:
        | Field             | Value                                             |
        | Type              | Business_Term                                     |
        | Name              | My Business Term                                  |
        | Description       | This is the first description of my business term |
      And the status of business concept with name "My Business Term" of type "Business_Term" is set to "draft" for version 2
      When "<user>" tries to modify a business concept "My Business Term" of type "Business_Term" with following data:
        | Field                 | Value                                              |
        | Type                  | Business_Term                                      |
        | Name                  | My Business Term                                   |
        | Description           | This is the second description of my business term |
        | Modification Comments | Modification on the Business Term description      |
      Then the system returns a result with code "<result>"
      And user <user> is able to view business concept "My Business Term" of type "Business_Term" and version "1" with following data:
        | Field             | Value                                                              |
        | Name              | My Business Term                                                   |
        | Type              | Business_Term                                                      |
        | Description       | This is the first description of my business term                  |
        | Last Modification | Some timestamp                                                     |
        | Last User         | app-admin                                                          |
        | Current           | false                                                              |
        | Version           | 1                                                                  |
        | Status            | published                                                          |
      And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business_Term" and version "2" with following data:
        | Field                 | Value                                                              |
        | Name                  | My Business Term                                                   |
        | Type                  | Business_Term                                                      |
        | Description           | This is the second description of my business term                 |
        | Modification Comments | Modification on the Business Term description                      |
        | Last Modification     | Some timestamp                                                     |
        | Last User             | app-admin                                                          |
        | Current               | true                                                               |
        | Version               | 2                                                                  |
        | Status                | draft                                                              |

      Examples:
        | user      | result       |
        | watcher   | Unauthorized |
        | creator   | Ok           |
        | publisher | Ok           |
        | admin     | Ok           |
