  Scenario Outline: Deprecation of existing Business Concept in Published status
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
      | Field       | Value                                             |
      | Type        | Business_Term                                     |
      | Name        | My Business Term                                  |
      | Description | This is the first description of my business term |
    And the business concept with name "My Business Term" of type "Business_Term" has been submitted for approval
    And the business concept with name "My Business Term" of type "Business_Term" has been published
    When <user> tries to deprecate a business concept "My Business Term" of type "Business_Term"
    Then the system returns a result with code "<result>"
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business_Term" and version "1" with following data:
      | Field       | Value                                             |
      | Type        | Business_Term                                     |
      | Name        | My Business Term                                  |
      | Description | This is the first description of my business term |
      | Status      | deprecated                                        |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Ok           |
      | admin     | Ok           |

  Scenario Outline: Deprecate a BC that has a second version published
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
      | Field       | Value                                             |
      | Type        | Business_Term                                     |
      | Name        | My Business Term                                  |
      | Description | This is the first description of my business term |
    And the business concept with name "My Business Term" of type "Business_Term" has been submitted for approval
    And the business concept with name "My Business Term" of type "Business_Term" has been published
    And the business concept with name "My Business Term" of type "Business_Term" has been copied as a new draft
    And the business concept with name "My Business Term" of type "Business_Term" has been submitted for approval
    And the business concept with name "My Business Term" of type "Business_Term" has been published
    When <user> tries to deprecate a business concept "My Business Term" of type "Business_Term"
    Then the system returns a result with code "<result>"
    And user <user> is able to view business concept "My Business Term" of type "Business_Term" and version "1" with following data:
      | Field             | Value                                             |
      | Name              | My Business Term                                  |
      | Type              | Business_Term                                     |
      | Description       | This is the first description of my business term |
      | Last Modification | Some timestamp                                    |
      | Last User         | app-admin                                         |
      | Current           | false                                             |
      | Version           | 1                                                 |
      | Status            | versioned                                         |
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business_Term" and version "2" with following data:
      | Field             | Value                                             |
      | Name              | My Business Term                                  |
      | Type              | Business_Term                                     |
      | Description       | This is the first description of my business term |
      | Last Modification | Some timestamp                                    |
      | Last User         | app-admin                                         |
      | Version           | 2                                                 |
      | Status            | deprecated                                        |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Ok           |
      | admin     | Ok           |
