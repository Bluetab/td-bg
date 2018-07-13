Scenario Outline: Delete existing Business Concept in Draft Status
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
  And the status of business concept with name "My Business Term" of type "Business Term" is set to "draft"
  When <user> tries to delete a business concept "My Business Term" of type "Business Term"
  Then the system returns a result with code "<result>"
  And if result <result> is "No Content", user <user> is not able to view business concept "My Business Term" of type "Business Term"
  And if result <result> is not "No Content", user <user> is able to view business concept "My Business Term" of type "Business Term" and version "1" with following data:
    | Field                 | Value                                              |
    | Type                  | Business Term                                      |
    | Name                  | My Business Term                                   |
    | Description           | This is the first description of my business term  |

  Examples:
    | user      | result       |
    | watcher   | Unauthorized |
    | creator   | No Content      |
    | publisher | No Content      |
    | admin     | No Content      |

  Scenario Outline: Delete existing Business Concept in Reject Status
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
      | Type              | Business Term                                     |subebuine
      | Name              | My Business Term                                  |
      | Description       | This is the first description of my business term |
    And the status of business concept with name "My Business Term" of type "Business Term" is set to "rejected"
    When <user> tries to delete a business concept "My Business Term" of type "Business Term"
    Then the system returns a result with code "<result>"
    And if result <result> is "No Content", user <user> is not able to view business concept "My Business Term" of type "Business Term"
    And if result <result> is not "No Content", user <user> is able to view business concept "My Business Term" of type "Business Term" and version "1" with following data:
      | Field                 | Value                                              |
      | Type                  | Business Term                                      |
      | Name                  | My Business Term                                   |
      | Description           | This is the first description of my business term  |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | No Content      |
      | publisher | No Content      |
      | admin     | No Content      |

    Scenario Outline: Delete current draft version for a BC that has been published previously
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
      When <user> tries to delete a business concept "My Business Term" of type "Business Term"
      Then the system returns a result with code "<result>"
      And user <user> is able to view business concept "My Business Term" of type "Business Term" and version "1" with following data:
        | Field             | Value                                                              |
        | Name              | My Business Term                                                   |
        | Type              | Business Term                                                      |
        | Description       | This is the first description of my business term                  |
        | Last Modification | Some timestamp                                                     |
        | Last User         | app-admin                                                          |
        | Current           | true                                                               |
        | Version           | 1                                                                  |
        | Status            | published                                                          |
      And if result <result> is "No Content",  business concept "My Business Term" of type "Business Term" and version "2" does not exist

      Examples:
        | user      | result       |
        | creator   | No Content      |
        | publisher | No Content      |
        | admin     | No Content      |


      Scenario Outline: Delete current draft version for a BC that has been published previously Unauthorized
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
        When <user> tries to delete a business concept "My Business Term" of type "Business Term"
        Then the system returns a result with code "<result>"
        And user <user> is able to view business concept "My Business Term" of type "Business Term" and version "1" with following data:
          | Field             | Value                                                              |
          | Name              | My Business Term                                                   |
          | Type              | Business Term                                                      |
          | Description       | This is the first description of my business term                  |
          | Last Modification | Some timestamp                                                     |
          | Last User         | app-admin                                                          |
          | Current           | false                                                               |
          | Version           | 1                                                                  |
          | Status            | published                                                          |
        And if result <result> is "No Content",  business concept "My Business Term" of type "Business Term" and version "2" does not exist

        Examples:
          | user      | result       |
          | watcher   | Unauthorized |
