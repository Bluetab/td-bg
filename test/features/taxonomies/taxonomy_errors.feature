Feature: taxonomy creation/edition errors

  Scenario: Creating a Data Domain without name
    Given an existing Domain Group called "DG 1"
    When user "app-admin" tries to create a Data Domain as child of Domain Group "DG 1" with following data:
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

  Scenario: Creating a Data Domain with a name already existing in a Domain Group
    Given an existing Domain Group called "DG 1"
    And an existing Data Domain called "DD 1" child of "DG 1"
    When user "app-admin" tries to create a Data Domain as child of Domain Group "DG 1" with following data:
      | name | description |
      | DD 1 |             |
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

  Scenario: Updating a Data Domain without name
    Given an existing Domain Group called "DG 1"
    And an existing Data Domain called "DD 1" child of "DG 1"
    When user "app-admin" tries to update a Data Domain called "DD 1" child of Domain Group "DG 1" with following data:
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

  Scenario: Updating a Data Domain and setting a name of an already existing DD in the same DG
    Given an existing Domain Group called "DG 1"
    And an existing Data Domain called "DD 1" child of "DG 1"
    And an existing Data Domain called "DD 2" child of "DG 1"
    When user "app-admin" tries to update a Data Domain called "DD 2" child of Domain Group "DG 1" with following data:
      | name  | description |
      | DD 1  | duplic      |

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

  Scenario: Creating a Domain Group without name
    When user "app-admin" tries to create a Domain Group with following data:
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

  Scenario: Creating a Domain Group with an already existing name
    Given an existing Domain Group called "DG 1"
    When user "app-admin" tries to create a Domain Group with following data:
      | name  | description |
      | DG 1  |             |
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

  Scenario: Creating a Business Concept with an already existing name
    Given an existing Domain Group called "My Parent Group"
    And an existing Data Domain called "My Domain" child of "My Parent Group"
    And an existing Business Concept type called "Business Term" with empty definition
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                                              |
      | Type              | Business Term                                                      |
      | Name              | My Date Business Term                                              |
      | Description       | This is the first description of my business term which is a date  |
    When "app-admin" tries to create a business concept in the Data Domain "My Domain" with following data:
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
    Given an existing Domain Group called "My Group"
    And an existing Data Domain called "My Domain" child of "My Group"
    And an existing Business Concept type called "Business Term" with empty definition
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                             |
      | Type              | Business Term                                     |
      | Name              | My Target Term                                    |
      | Description       | This is my Target Term                            |
    When "app-admin" tries to create a business concept in the Data Domain "My Domain" with following data:
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
    Given an existing Domain Group called "My Parent Group"
    And an existing Data Domain called "My Domain" child of "My Parent Group"
    When "app-admin" tries to create a business concept in the Data Domain "My Domain" with following data:
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
    Given an existing Domain Group called "My Parent Group"
    And an existing Data Domain called "My Domain" child of "My Parent Group"
    And an existing Business Concept type called "Business Term" with empty definition
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
      | Field             | Value                                                              |
      | Type              | Business Term                                                      |
      | Name              | My Date Business Term                                              |
      | Description       | This is the first description of my business term which is a date  |
    And an existing Business Concept of type "Business Term" in the Data Domain "My Domain" with following data:
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

