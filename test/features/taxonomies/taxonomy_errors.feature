Feature: taxonomy creation/edition errors

  Scenario: Creating a Domain without name
    Given an existing Domain called "Domain 1"
    When user "app-admin" tries to create a Domain as child of Domain "Domain 1" with following data:
      | name | description |
      |      | noname      |

    Then the system returns a result with code "Unprocessable Entity"
    And the system returns a response with following data:
    """
    {
      "errors": {
        "name": [
          "blank"
        ]
      }
    }
    """

  Scenario: Updating a Domain without name
    Given an existing Domain called "Domain Parent 1"
    And an existing Domain called "Domain Child 1" child of Domain "Domain Parent 1"
    When user "app-admin" tries to update a Domain called "Domain Child 1" child of Domain "Domain Parent 1" with following data:
      | name | description |
      |      | noname      |

    Then the system returns a result with code "Unprocessable Entity"
    And the system returns a response with following data:
    """
    {
      "errors": {
        "name": [
          "blank"
        ]
      }
    }
    """

  Scenario: Creating a Domain without name
    When user "app-admin" tries to create a Domain with following data:
      | name  | description |
      |       |             |
    Then the system returns a result with code "Unprocessable Entity"
    And the system returns a response with following data:
    """
    {
      "errors": {
        "name": [
          "blank"
        ]
      }
    }
    """

  Scenario: Creating a Business Concept with an already existing name
    Given an existing Domain called "My Parent Domain"
    And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
    And an existing Business Concept type called "Business Term" with empty definition
    And an existing Business Concept of type "Business Term" in the Domain "My Child Domain" with following data:
      | Field             | Value                                                              |
      | Type              | Business Term                                                      |
      | Name              | My Date Business Term                                              |
      | Description       | This is the first description of my business term which is a date  |
    When "app-admin" tries to create a business concept in the Domain "My Child Domain" with following data:
      | Field             | Value                                                                   |
      | Type              | Business Term                                                           |
      | Name              | My Date Business Term                                                   |
      | Description       | This is the first description of my business term which is very simple  |
    Then the system returns a result with code "Unprocessable Entity"
    And the system returns a response with following data:
    """
    {
      "errors": {
        "name": [
          "unique"
        ]
      }
    }
    """


  Scenario: Can not create a relation between not published business concepts
    Given an existing Domain called "My Parent Domain"
    And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
    And an existing Business Concept type called "Business Term" with empty definition
    And an existing Business Concept of type "Business Term" in the Domain "My Child Domain" with following data:
      | Field             | Value                                             |
      | Type              | Business Term                                     |
      | Name              | My Target Term                                    |
      | Description       | This is my Target Term                            |
    When "app-admin" tries to create a business concept in the Domain "My Child Domain" with following data:
      | Field             | Value                                             |
      | Type              | Business Term                                     |
      | Name              | My Origin Term                                    |
      | Description       | This is my origin term                            |
      | Related To        | My Target Term                                    |
    Then the system returns a result with code "Unprocessable Entity"
    And the system returns a response with following data:
    """
    {
      "errors": {
        "related_to": [
          "invalid"
        ]
      }
    }
    """

  Scenario: Creating a Business Concept without type
    Given an existing Domain called "My Parent Domain"
    And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
    When "app-admin" tries to create a business concept in the Domain "My Child Domain" with following data:
      | Field             | Value                                                                   |
      | Name              | My Date Business Term                                                   |
      | Description       | This is the first description of my business term which is very simple  |
    Then the system returns a result with code "Unprocessable Entity"
    And the system returns a response with following data:
    """
    {
      "errors": {
        "type": [
          "blank"
        ]
      }
    }
    """

  Scenario: Updating a Business Concept name to an already existing one
    Given an existing Domain called "My Parent Domain"
    And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
    And an existing Business Concept type called "Business Term" with empty definition
    And an existing Business Concept of type "Business Term" in the Domain "My Child Domain" with following data:
      | Field             | Value                                                              |
      | Type              | Business Term                                                      |
      | Name              | My Date Business Term                                              |
      | Description       | This is the first description of my business term which is a date  |
    And an existing Business Concept of type "Business Term" in the Domain "My Child Domain" with following data:
      | Field             | Value                                                              |
      | Type              | Business Term                                                      |
      | Name              | Business Term 2                                                    |
      | Description       | This is the first description of my business term which is a date  |
    When "app-admin" tries to modify a business concept "My Date Business Term" of type "Business Term" with following data:
      | Field             | Value                                                              |
      | Name              | Business Term 2                                                    |
    Then the system returns a result with code "Unprocessable Entity"
    And the system returns a response with following data:
      """
      {
        "errors": {
          "name": [
            "unique"
          ]
        }
      }
      """
