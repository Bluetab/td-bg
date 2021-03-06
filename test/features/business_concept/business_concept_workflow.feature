  Scenario Outline: Sending business concept for approval
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
      | Field       | Value                                                             |
      | Type        | Business_Term                                                     |
      | Name        | My Date Business Term                                             |
      | Description | This is the first description of my business term which is a date |
    When "<user>" tries to send for approval a business concept with name "My Date Business Term" of type "Business_Term"
    Then the system returns a result with code "<result>"
    And if result <result> is "Ok", user <user> is able to view business concept "My Date Business Term" of type "Business_Term" with following data:
      | Field             | Value                                                             |
      | Name              | My Date Business Term                                             |
      | Type              | Business_Term                                                     |
      | Description       | This is the first description of my business term which is a date |
      | Last Modification | Some timestamp                                                    |
      | Last User         | app-admin                                                         |
      | Current           | true                                                              |
      | Version           | 1                                                                 |
      | Status            | pending_approval                                                  |
    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Ok           |
      | publisher | Ok           |
      | admin     | Ok           |

  Scenario Outline: Publish existing Business Concept in Pending Approval status
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
      | Field       | Value                                                             |
      | Type        | Business_Term                                                     |
      | Name        | My Business Term                                                  |
      | Description | This is the first description of my business term which is a date |
    And the business concept with name "My Business Term" of type "Business_Term" has been submitted for approval
    When <user> tries to publish a business concept with name "My Business Term" of type "Business_Term"
    Then the system returns a result with code "<result>"
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business_Term" with following data:
      | Field             | Value                                                             |
      | Name              | My Business Term                                                  |
      | Type              | Business_Term                                                     |
      | Description       | This is the first description of my business term which is a date |
      | Last Modification | Some timestamp                                                    |
      | Last User         | app-admin                                                         |
      | Current           | true                                                              |
      | Version           | 1                                                                 |
      | Status            | published                                                         |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Ok           |
      | admin     | Ok           |

  Scenario Outline: Reject existing Business Concept in Pending Approval status
    Given an existing Domain called "My Parent Domain"
    And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
    And an existing Domain called "My Domain" child of Domain "My Child Domain"
    And following users exist with the indicated role in Domain "My Domain"
      | user      | role    |
      | creator   | create  |
      | watcher   | watch   |
      | publisher | publish |
      | admin     | admin   |
    And an existing Business Concept type called "Business_Term" with empty definition
    And an existing Business Concept of type "Business_Term" in the Domain "My Domain" with following data:
      | Field       | Value                                             |
      | Type        | Business_Term                                     |
      | Name        | My Business Term                                  |
      | Description | This is the first description of my business term |
    And the business concept with name "My Business Term" of type "Business_Term" has been submitted for approval
    When <user> tries to reject a business concept with name "My Business Term" of type "Business_Term" and reject reason "Description is not accurate"
    Then the system returns a result with code "<result>"
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business_Term" with following data:
      | Field             | Value                                             |
      | Name              | My Business Term                                  |
      | Type              | Business_Term                                     |
      | Description       | This is the first description of my business term |
      | Last Modification | Some timestamp                                    |
      | Last User         | app-admin                                         |
      | Current           | true                                              |
      | Version           | 1                                                 |
      | Status            | rejected                                          |
      | Reject Reason     | Description is not accurate                       |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Ok           |
      | admin     | Ok           |

  Scenario Outline: Publish a second version of a Business Concept
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
    And business concept with name "My Business Term" of type "Business_Term" has been modified with following data:
      | Field                 | Value                                              |
      | Type                  | Business_Term                                      |
      | Name                  | My Business Term                                   |
      | Description           | This is the second description of my business term |
      | Modification Comments | Modification on the Business Term description      |
    And the business concept with name "My Business Term" of type "Business_Term" has been submitted for approval
    When <user> tries to publish a business concept with name "My Business Term" of type "Business_Term"
    Then the system returns a result with code "<result>"
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business_Term" and version "2" with following data:
      | Field             | Value                                              |
      | Name              | My Business Term                                   |
      | Type              | Business_Term                                      |
      | Description       | This is the second description of my business term |
      | Last Modification | Some timestamp                                     |
      | Last User         | <user>                                             |
      | Current           | true                                               |
      | Version           | 2                                                  |
      | Status            | published                                          |
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business_Term" and version "1" with following data:
      | Field             | Value                                             |
      | Name              | My Business Term                                  |
      | Type              | Business_Term                                     |
      | Description       | This is the first description of my business term |
      | Last Modification | Some timestamp                                    |
      | Last User         | <user>                                            |
      | Current           | false                                             |
      | Version           | 1                                                 |
      | Status            | versioned                                         |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Ok           |
      | admin     | Ok           |


  Scenario Outline: Send for Approval a draft version of a BC previously published
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
    When "<user>" tries to send for approval a business concept with name "My Business Term" of type "Business_Term"
    Then the system returns a result with code "<result>"
    And user <user> is able to view business concept "My Business Term" of type "Business_Term" and version "1" with following data:
      | Field             | Value                                             |
      | Name              | My Business Term                                  |
      | Type              | Business_Term                                     |
      | Description       | This is the first description of my business term |
      | Last Modification | Some timestamp                                    |
      | Last User         | app-admin                                         |
      | Current           | true                                             |
      | Version           | 1                                                 |
      | Status            | published                                         |
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business_Term" and version "2" with following data:
      | Field             | Value                                             |
      | Name              | My Business Term                                  |
      | Type              | Business_Term                                     |
      | Description       | This is the first description of my business term |
      | Last Modification | Some timestamp                                    |
      | Last User         | app-admin                                         |
      | Current           | false                                              |
      | Version           | 2                                                 |
      | Status            | pending_approval                                  |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Ok           |
      | publisher | Ok           |
      | admin     | Ok           |

  Scenario Outline: Reject a pending approval BC that has previously been published
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
    When <user> tries to reject a business concept with name "My Business Term" of type "Business_Term" and reject reason "Description is not accurate"
    Then the system returns a result with code "<result>"
    And user <user> is able to view business concept "My Business Term" of type "Business_Term" and version "1" with following data:
      | Field             | Value                                             |
      | Name              | My Business Term                                  |
      | Type              | Business_Term                                     |
      | Description       | This is the first description of my business term |
      | Last Modification | Some timestamp                                    |
      | Last User         | app-admin                                         |
      | Current           | true                                             |
      | Version           | 1                                                 |
      | Status            | published                                         |
    And if result <result> is "Ok", user <user> is able to view business concept "My Business Term" of type "Business_Term" and version "2" with following data:
      | Field             | Value                                             |
      | Name              | My Business Term                                  |
      | Type              | Business_Term                                     |
      | Description       | This is the first description of my business term |
      | Last Modification | Some timestamp                                    |
      | Last User         | app-admin                                         |
      | Current           | false                                              |
      | Version           | 2                                                 |
      | Status            | rejected                                          |
      | Reject Reason     | Description is not accurate                       |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Ok           |
      | admin     | Ok           |
