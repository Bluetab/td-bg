Feature: Taxonomy Navigation allows to navigate throw all the Domains in order to get
         the corresponding Business Concepts

  Scenario: List of all business concepts child of a Domain
     Given an existing Domain called "My Parent Domain"
     And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
     And an existing Domain called "My Domain" child of Domain "My Child Domain"
     And an existing Domain called "My Second Domain" child of Domain "My Child Domain"
     And an existing Business Concept type called "Business Term" with empty definition
     And an existing Business Concept type called "Policy" with empty definition
     And an existing Business Concept of type "Business Term" in the Domain "My Domain" with following data:
       | Field             | Value                                                              |
       | Type              | Business Term                                                      |
       | Name              | My First Business Concept of this type                             |
       | Description       | This is the first description of my first business term            |
     And an existing Business Concept of type "Business Term" in the Domain "My Domain" with following data:
       | Field             | Value                                                              |
       | Type              | Business Term                                                      |
       | Name              | My Second Business Concept of this type                            |
       | Description       | This is the first description of my second business term           |
     And an existing Business Concept of type "Policy" in the Domain "My Domain" with following data:
       | Field             | Value                                                              |
       | Type              | Policy                                                             |
       | Name              | My First Business Concept of this type                             |
       | Description       | This is the first description of my first policy                   |
     And an existing Business Concept of type "Policy" in the Domain "My Second Domain" with following data:
       | Field             | Value                                                              |
       | Type              | Policy                                                             |
       | Name              | My Second Business Concept of this type                            |
       | Description       | This is the first description of my second policy                  |
     When user "app-admin" tries to query a list of all Business Concepts children of Domain "My Domain"
     Then user sees following business concepts list:
       | name                                    | type           | status | description                                              |
       | My First Business Concept of this type  | Business Term  | draft  | This is the first description of my first business term  |
       | My Second Business Concept of this type | Business Term  | draft  | This is the first description of my second business term |
       | My First Business Concept of this type  | Policy         | draft  | This is the first description of my first policy         |

  Scenario: List of all business concepts child of a Domain
    Given an existing Domain called "My Parent Domain"
    And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
    And an existing Domain called "My Domain" child of Domain "My Child Domain"
    And an existing Domain called "My Second Domain" child of Domain "My Child Domain"
    And an existing Business Concept type called "Business Term" with empty definition
    And an existing Business Concept type called "Policy" with empty definition
    And an existing Business Concept of type "Business Term" in the Domain "My Domain" with following data:
      | Field             | Value                                                              |
      | Type              | Business Term                                                      |
      | Name              | My First Business Concept of this type                             |
      | Description       | This is the first description of my first business term            |
    And an existing Business Concept of type "Business Term" in the Domain "My Domain" with following data:
      | Field             | Value                                                              |
      | Type              | Business Term                                                      |
      | Name              | My Second Business Concept of this type                            |
      | Description       | This is the first description of my second business term           |
    And an existing Business Concept of type "Policy" in the Domain "My Domain" with following data:
      | Field             | Value                                                              |
      | Type              | Policy                                                             |
      | Name              | My First Business Concept of this type                             |
      | Description       | This is the first description of my first policy                   |
    And an existing Business Concept of type "Policy" in the Domain "My Second Domain" with following data:
      | Field             | Value                                                              |
      | Type              | Policy                                                             |
      | Name              | My Second Business Concept of this type                            |
      | Description       | This is the first description of my second policy                  |
    When user "app-admin" tries to query a list of all Business Concepts children of Domain "My Domain"
    Then user sees following business concepts list:
      | name                                    | type           | status | description                                              |
      | My First Business Concept of this type  | Business Term  | draft  | This is the first description of my first business term  |
      | My Second Business Concept of this type | Business Term  | draft  | This is the first description of my second business term |
      | My First Business Concept of this type  | Policy         | draft  | This is the first description of my first policy         |
