Feature: List of comments of a Business Concept
  Authenticated users should be able to create/update/listing comments on a Business Concept

Scenario: Create comment on a Business Concept
    Given an existing Domain called "Domain 1"
    And an existing Business Concept type called "Business Term" with empty definition
    And an existing Business Concept in the Domain "Domain 1" with following data:
      | Field             | Value                                                                   |
      | Type              | Business Term                                                           |
      | Name              | My Business Term                                                        |
      | Description       | This is the first description of my business term which is very simple  |
    When "app-admin" tries to create a new comment "This is my first comment" on the business concept "My Business Term"
    Then the system returns a result with code "Created"
    And if result "Created" the user "app-admin" should be able to list the comments of the business concept "My Business Term"
    Then the system returns a result with code "Ok"
    And the comment "This is my first comment" created by user "app-admin" is present in the retrieved list