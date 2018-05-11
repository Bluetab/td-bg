Feature: Taxonomy Roles of A BusinessConcept
  Authenticated users with a minumun "watcher" role sholud be able to query the roles over a taxonomy of a BusinessConcept

  Scenario: List of the taxonomy roles whithin the BusinessConcept hierarchy
    Given an existing Domain called "Domain 1"
    And an existing Domain called "Domain 1.1" child of Domain "Domain 1"
    And an existing Domain called "Domain 1.1.1" child of Domain "Domain 1.1"
    And an existing Domain called "Domain 1.1.2" child of Domain "Domain 1.1"
    And an existing Business Concept type called "Business Term" with empty definition
    And an existing Business Concept in the Domain "Domain 1.1.2" with following data:
      | Field             | Value                                                                   |
      | Type              | Business Term                                                           |
      | Name              | My Business Term                                                        |
      | Description       | This is the first description of my business term which is very simple  |
    And following users exist in the application:
      | user           |
      | pietro.alpin   |
      | watcher        |
      | unauth         |
    And following users exist with the indicated role in Domain "Domain 1"
      | user           | role    |
      | pietro.alpin   | publish |
    And following users exist with the indicated role in Domain "Domain 1.1.2"
      | user           | role    |
      | pietro.alpin   | watch   |
    And following users exist with the indicated role in Domain "Domain 1"
      | user      | role    |
      | watcher   | watch   |
    When user "watcher" lists taxonomy roles of the business concept "My Business Term"
    Then the system returns a result with code "Ok"
    And if result "Ok" the system will return the user "pietro.alpin" with a role "publish" in the domain "Domain 1"
    When user "unauth" lists taxonomy roles of the business concept "My Business Term"
    Then the system returns a result with code "Unauthorized"
