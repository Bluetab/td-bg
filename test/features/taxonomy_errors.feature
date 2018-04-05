Feature: taxonomy creation/edition errors

  Scenario: Creating a Data Domain without name
    Given an existing Domain Group called "DG 1"
    And application locale is "es"
    When user "app-admin" tries to create a Data Domain as child of Domain Group "DG 1" with following data:
      | name | description |
      |      | noname      |

    Then the system returns a result with code "Unprocessable Entity"
    And the system returns a response with following data:
    """
    {
      "errors": {
        "name": [
          "requerido"
        ]
      }
    }
    """