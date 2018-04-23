Scenario Outline: Create a alias for a business concept
  Given an existing Domain called "My Parent Domain"
  And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
  And following users exist with the indicated role in Domain "My Child Domain"
    | user      | role    |
    | watcher   | watch   |
    | creator   | create  |
    | publisher | publish |
    | admin     | admin   |
  And an existing Business Concept type called "Business Term" with empty definition
  And an existing Business Concept of type "Business Term" in the Domain "My Child Domain" with following data:
    | Field             | Value                                             |
    | Type              | Business Term                                     |
    | Name              | My Business Term                                  |
    | Description       | This is the first description of my business term |
When "<user>" tries to create a new alias "My Synonym Term" for business concept with name "My Business Term" of type "Business Term"
Then the system returns a result with code "<result>"
And if <result> is "Created", user <user> is able to see following list of aliases for business concept with name "My Business Term" of type "Business Term"
    | name           |
    | My Synonym Term |

Examples:
  | user      | result       |
  | watcher   | Unauthorized |
  | creator   | Unauthorized |
  | publisher | Created      |
  | admin     | Created      |

Scenario Outline: Delete alias for a business concept
  Given an existing Domain called "My Parent Domain"
  And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
  And following users exist with the indicated role in Domain "My Child Domain"
    | user      | role    |
    | watcher   | watch   |
    | creator   | create  |
    | publisher | publish |
    | admin     | admin   |
  And an existing Business Concept type called "Business Term" with empty definition
  And an existing Business Concept of type "Business Term" in the Domain "My Child Domain" with following data:
    | Field             | Value                                             |
    | Type              | Business Term                                     |
    | Name              | My Business Term                                  |
    | Description       | This is the first description of my business term |
  And business concept with name "My Business Term" of type "Business Term" has an alias "My Synonym Term"
  And business concept with name "My Business Term" of type "Business Term" has an alias "My Second Synonym Term"
  When <user> tries to delete alias "My Synonym Term" for business concept with name "My Business Term" of type "Business Term"
  Then the system returns a result with code "<result>"
  And if <result> is "Deleted", user <user> is able to see following list of aliases for business concept with name "My Business Term" of type "Business Term"
      | name                  |
      | My Second Synonym Term |
  And if <result> is not "Deleted", user <user> is able to see following list of aliases for business concept with name "My Business Term" of type "Business Term"
      | name                  |
      | My Synonym Term        |
      | My Second Synonym Term |

  Examples:
    | user      | result       |
    | watcher   | Unauthorized |
    | creator   | Unauthorized |
    | publisher | Deleted      |
    | admin     | Deleted      |

  Scenario: User should not be able to create an alias with same type and name as an existing business concept
    Given an existing Domain called "My Parent Group"
    And an existing Domain called "My Child Domain" child of Domain "My Parent Group"
    And an existing Business Concept type called "Business Term" with empty definition
    And an existing Business Concept in the Domain "My Child Domain" with following data:
     | Field             | Value                                                                   |
     | Type              | Business Term                                                           |
     | Name              | My Business Term                                                        |
     | Description       | This is the first description of my business term which is very simple  |
    And an existing Domain called "My Second Parent Group"
    And an existing Domain called "My Second Domain" child of Domain "My Second Parent Group"
    And an existing Business Concept in the Domain "My Child Domain" with following data:
     | Field             | Value                                                                          |
     | Type              | Business Term                                                                  |
     | Name              | Second Business Term                                                           |
     | Description       | This is the first description of my second business term which is very simple  |
    When "app-admin" tries to create a new alias "Second Business Term" for business concept with name "My Business Term" of type "Business Term"
    Then the system returns a result with code "Unprocessable Entity"
    And user "app-admin" is able to see following list of aliases for business concept with name "My Business Term" of type "Business Term"
      | name           |
