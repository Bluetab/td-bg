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