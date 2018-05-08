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
   And an existing Business Concept type called "Business Term" with following definition:
    | Field            | Format        | Max Size | Values                                       | Mandatory | Default Value | Group      |
    | Formula          | string        | 100      |                                              |    NO     |               | General    |
    | Format           | list          |          | Date, Numeric, Amount, Text                  |    YES    |               | General    |
    | List of Values   | variable_list | 100      |                                              |    NO     |               | Functional |
    | Sensitive Data    | list         |          | N/A, Personal Data, Related to personal Data |    NO     | N/A           | Functional |
    | Update Frequence | list          |          | Not defined, Daily, Weekly, Monthly, Yearly  |    NO     | Not defined   | General    |
    | Related Area     | string        | 100      |                                              |    NO     |               | Functional |
    | Default Value    | string        | 100      |                                              |    NO     |               | General    |
    | Additional Data  | string        | 500      |                                              |    NO     |               | Functional |
   And an existing Business Concept of type "Business Term" in the Domain "My Domain" with following data:
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
   When "<user>" tries to modify a business concept "My Date Business Term" of type "Business Term" with following data:
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
   And an existing Business Concept type called "Business Term" with empty definition
   And an existing Business Concept of type "Business Term" in the Domain "My Domain" with following data:
     | Field             | Value                                             |
     | Type              | Business Term                                     |
     | Name              | My Business Term                                  |
     | Description       | This is the first description of my business term |
   And the status of business concept with name "My Business Term" of type "Business Term" is set to "published"
   When "<user>" tries to modify a business concept "My Business Term" of type "Business Term" with following data:
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
     And an existing Business Concept type called "Business Term" with empty definition
     And an existing Business Concept of type "Business Term" in the Domain "My Domain" with following data:
       | Field             | Value                                             |
       | Type              | Business Term                                     |
       | Name              | My Business Term                                  |
       | Description       | This is the first description of my business term |
     And the status of business concept with name "My Business Term" of type "Business Term" is set to "published" for version 2
     When "<user>" tries to modify a business concept "My Business Term" of type "Business Term" with following data:
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
    And an existing Business Concept type called "Business Term" with empty definition
    And an existing Business Concept of type "Business Term" in the Domain "My Domain" with following data:
      | Field             | Value                                             |
      | Type              | Business Term                                     |
      | Name              | My Business Term                                  |
      | Description       | This is the first description of my business term |
    And the status of business concept with name "My Business Term" of type "Business Term" is set to "rejected"
    When "<user>" tries to modify a business concept "My Business Term" of type "Business Term" with following data:
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
      And an existing Business Concept type called "Business Term" with empty definition
      And an existing Business Concept of type "Business Term" in the Domain "My Domain" with following data:
        | Field             | Value                                             |
        | Type              | Business Term                                     |
        | Name              | My Business Term                                  |
        | Description       | This is the first description of my business term |
      And the status of business concept with name "My Business Term" of type "Business Term" is set to "draft" for version 2
      When "<user>" tries to modify a business concept "My Business Term" of type "Business Term" with following data:
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
        | Current           | false                                                              |
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
        | Current               | true                                                              |
        | Version               | 2                                                                  |
        | Status                | draft                                                              |

      Examples:
        | user      | result       |
        | watcher   | Unauthorized |
        | creator   | Ok           |
        | publisher | Ok           |
        | admin     | Ok           |
