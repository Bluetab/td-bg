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
