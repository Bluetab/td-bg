Background:
  Given an existing Domain called "My Parent Group"

Scenario: Create a simple business concept
  Given an existing Domain called "My Child Domain" child of Domain "My Parent Group"
  And an existing Domain called "My Domain" child of Domain "My Child Domain"
  And an existing Business Concept type called "Business_Term" with empty definition
  When "app-admin" tries to create a business concept in the Domain "My Domain" with following data:
    | Field             | Value                                                                   |
    | Type              | Business_Term                                                           |
    | Name              | My Simple Business Term                                                 |
    | Description       | This is the first description of my business term which is very simple  |
  Then the system returns a result with code "Created"
  And "app-admin" is able to view business concept "My Simple Business Term" as a child of Domain "My Domain" with following data:
    | Field             | Value                                                                    |
    | Type              | Business_Term                                                            |
    | Name              | My Simple Business Term                                                  |
    | Description       | This is the first description of my business term which is very simple   |
    | Status            | draft                                                                    |
    | Last Modification | Some Timestamp                                                           |
    | Last User         | app-admin                                                                |
    | Current           | true                                                                     |
    | Version           | 1                                                                        |

Scenario: Create a business concept with dynamic data
  Given an existing Domain called "My Child Domain" child of Domain "My Parent Group"
  And an existing Domain called "My Domain" child of Domain "My Child Domain"
  And an existing Business Concept type called "Business_Term" with following definition:
   | Field            | Max Size | Values                                        | Cardinality | Default Value | Group      |
   | Formula          | 100      |                                               |    ?        |               | General    |
   | List of Values   | 100      |                                               |    ?        |               | Functional |
   | Sensitive Data   |          | N/A, Personal Data, Related to personal Data  |    ?        | N/A           | Functional |
   | Update Frequence |          | Not defined, Daily, Weekly, Monthly, Yearly   |    ?        | Not defined   | General    |
   | Related Area     | 100      |                                               |    ?        |               | Functional |
   | Default Value    | 100      |                                               |    ?        |               | General    |
   | Additional Data  | 500      |                                               |    ?        |               | Functional |
  When "app-admin" tries to create a business concept in the Domain "My Domain" with following data:
    | Field             | Value                                                                    |
    | Type              | Business_Term                                                            |
    | Name              | My Dinamic Business Term                                                 |
    | Description       | This is the first description of my business term which is a date        |
    | Formula           |                                                                          |
    | List of Values    |                                                                          |
    | Related Area      |                                                                          |
    | Default Value     |                                                                          |
    | Additional Data   |                                                                          |
  Then the system returns a result with code "Created"
  And "app-admin" is able to view business concept "My Dinamic Business Term" as a child of Domain "My Domain" with following data:
    | Field             | Value                                                              |
    | Name              | My Dinamic Business Term                                           |
    | Type              | Business_Term                                                      |
    | Description       | This is the first description of my business term which is a date  |
    | Formula           |                                                                    |
    | List of Values    |                                                                    |
    | Sensitive Data    | N/A                                                                |
    | Update Frequence  | Not defined                                                        |
    | Related Area      |                                                                    |
    | Default Value     |                                                                    |
    | Additional Data   |                                                                    |
    | Status            | draft                                                              |
    | Last Modification | Some timestamp                                                     |
    | Last User         | app-admin                                                          |
    | Current           | true                                                               |
    | Version           | 1                                                                  |

Scenario Outline: Creating a business concept depending on your role
  Given an existing Domain called "My Child Domain" child of Domain "My Parent Group"
  And an existing Domain called "My Domain" child of Domain "My Child Domain"
  And an existing Business Concept type called "Business_Term" with empty definition
  And following users exist with the indicated role in Domain "My Domain"
    | user      | role    |
    | watcher   | watch   |
    | creator   | create  |
    | publisher | publish |
    | admin     | admin   |
  When "<user>" tries to create a business concept in the Domain "My Domain" with following data:
    | Field             | Value                                                                   |
    | Type              | Business_Term                                                           |
    | Name              | My Simple Business Term                                                 |
    | Description       | This is the first description of my business term which is very simple  |
  Then the system returns a result with code "<result>"
  Examples:
    | user      | result       |
    | watcher   | Unauthorized |
    | creator   | Created      |
    | publisher | Created      |
    | admin     | Created      |

  Scenario: User should not be able to create a business concept with same type and name as an existing one
    Given an existing Domain called "My Domain" child of Domain "My Parent Group"
    And an existing Business Concept type called "Business_Term" with empty definition
    And an existing Business Concept in the Domain "My Domain" with following data:
     | Field             | Value                                                                   |
     | Type              | Business_Term                                                           |
     | Name              | My Business Term                                                        |
     | Description       | This is the first description of my business term which is very simple  |
    And an existing Domain called "My Second Parent Group"
    And an existing Domain called "My Second Domain" child of Domain "My Second Parent Group"
    When "app-admin" tries to create a business concept in the Domain "My Second Domain" with following data:
     | Field             | Value                                                                   |
     | Type              | Business_Term                                                           |
     | Name              | My Business Term                                                        |
     | Description       | This is the second description of my business term                      |
    Then the system returns a result with code "Unprocessable Entity"
    And "app-admin" is able to view business concept "My Business Term" as a child of Domain "My Domain" with following data:
      | Field             | Value                                                                   |
      | Type              | Business_Term                                                           |
      | Name              | My Business Term                                                        |
      | Description       | This is the first description of my business term which is very simple  |
      | Status            | draft                                                                   |
      | Last Modification | Some Timestamp                                                          |
      | Last User         | app-admin                                                               |
      | Current           | true                                                                    |
      | Version           | 1                                                                       |
    And "app-admin" is not able to view business concept "My Business Term" as a child of Domain "My Second Domain"

  Scenario: User should not be able to create a business concept with same type and name as an existing alias
    Given an existing Domain called "My Domain" child of Domain "My Parent Group"
    And an existing Business Concept type called "Business_Term" with empty definition
    And an existing Business Concept in the Domain "My Domain" with following data:
     | Field             | Value                                                                   |
     | Type              | Business_Term                                                           |
     | Name              | My Business Term                                                        |
     | Description       | This is the first description of my business term which is very simple  |
    And business concept with name "My Business Term" of type "Business_Term" has an alias "My Synonym Term"
    And an existing Domain called "My Second Parent Group"
    And an existing Domain called "My Second Domain" child of Domain "My Second Parent Group"
    When "app-admin" tries to create a business concept in the Domain "My Second Domain" with following data:
     | Field             | Value                                                                   |
     | Type              | Business_Term                                                           |
     | Name              | My Synonym Term                                                         |
     | Description       | This is the second description of my business term                      |
    Then the system returns a result with code "Unprocessable Entity"
    And business concept "My Synonym Term" of type "Business_Term" and version "1" does not exist
