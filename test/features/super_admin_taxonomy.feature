Feature: Super-admin Taxonomy administration
  This feature will allow a super-admin user to create all levels of taxonomy necessary to classify the content defined within the application.
  We will have data domains as containers of content and Domain Groups as grouping entities for domains or other Domain Groups

  # Background:
  #   Given user "app-admin" is logged in the application

  Scenario: Creating a Domain Group without any parent
    When user "app-admin" tries to create a Domain Group with the name "Financial Metrics" and following data:
      | Description |
      | First version of Financial Metrics |
    Then the system returns a result with code "Created"
    And the user "app-admin" is able to see the Domain Group "Financial Metrics" with following data:
      | Description |
      | First version of Financial Metrics |

  Scenario: Creating a Domain Group as child of an existing Domain Group
    Given an existing Domain Group called "Risks"
    When user "app-admin" tries to create a Domain Group with the name "Markets" as child of Domain Group "Risks" with following data:
      | Description |
      | First version of Markets |
    Then the system returns a result with code "Created"
    And the user "app-admin" is able to see the Domain Group "Markets" with following data:
      | Description |
      | First version of Markets |
    And Domain Group "Markets" is a child of Domain Group "Risks"

  # Scenario: Creating a Domain Group as child of a non existing Domain Group
  #   Given user "app-admin" is logged in the application
  #   When user "app-admin" tries to create a Domain Group with the name "Markets" as child of Domain Group "Imaginary Group" with following data:
  #     | Description |
  #     | First version of Markets |
  #   Then the system returns a result with code "NotFound"
  #   And the user "app-admin" is not able to see the Domain Group "Imaginary Group"
  #

  Scenario: Creating a duplicated Domain Group
    Given an existing Domain Group called "Risks"
    When user "app-admin" tries to create a Domain Group with the name "Risks" and following data:
      | Description |
      | First version of Risks |
    Then the system returns a result with code "Unprocessable Entity"

  Scenario: Creating a Data Domain depending on an existing Domain Group
    Given an existing Domain Group called "Risks"
    When user "app-admin" tries to create a Data Domain with the name "Operational Risk" as child of Domain Group "Risks" with following data:
       | Description |
       | First version of Operational Risk |
    Then the system returns a result with code "Created"
    And the user "app-admin" is able to see the Data Domain "Operational Risk" with following data:
       | Description |
       | First version of Operational Risk |
    And Data Domain "Operational Risk" is a child of Domain Group "Risks"
  #
  # Scenario: Creating a Data Domain depending on a non existing Domain Group
  #   Given user "app-admin" is logged in the application
  #   When user "app-admin" tries to create a Data Domain with the name "Operational Risk" as child of Domain Group "Imaginary Group" with following data:
  #     | Description |
  #     | First version of Operational Risk |
  #   Then the system returns a result with code "Forbidden"
  #   And the user "app-admin" is not able to see the Domain Group "Imaginary Group"
  #

  Scenario: Creating a duplicated Data Domain depending on the same existing Domain Group
    Given an existing Domain Group called "Risks"
    And an existing Data Domain called "Operational Risk" child of Domain Group "Risks"
    When user "app-admin" tries to create a Data Domain with the name "Operational Risk" as child of Domain Group "Risks" with following data:
      | Description |
      | First version of Operational Risk |
    Then the system returns a result with code "Unprocessable Entity"

  Scenario: Modifying a Domain Group and seeing the new version
     Given an existing Domain Group called "Risks" with following data:
       | Description |
       | First version of Risks |
     When user "app-admin" tries to modify a Domain Group with the name "Risks" introducing following data:
       | Description |
       | Second version of Risks |
     Then the system returns a result with code "Ok"
     And the user "app-admin" is able to see the Domain Group "Risks" with following data:
       | Description |
       | Second version of Risks |

  # Scenario: Trying to modify a non existing Domain Group
  #   Given user "app-admin" is logged in the application
  #   When user "app-admin" tries to modify a Domain Group with the name "Imaginary Group" introducing following data:
  #     | Description |
  #     | Second version of Imaginary Group |
  #   Then the system returns a result with code "Forbidden"
  #   And the user "app-admin" is not able to see the Domain Group "Risks"
  #
   Scenario: Modifying a Data Domain and seeing the new version
     Given an existing Domain Group called "Risks"
     And an existing Data Domain called "Credit Risks" child of Domain Group "Risks" with following data:
       | Description |
       | First version of Credit Risks |
     When user "app-admin" tries to modify a Data Domain with the name "Credit Risks" introducing following data:
       | Description |
       | Second version of Credit Risks |
     Then the system returns a result with code "Ok"
     And the user "app-admin" is able to see the Data Domain "Credit Risks" with following data:
       | Description |
       | Second version of Credit Risks |

   Scenario: Deleting a Domain Group without any Group or Domain pending on it
     Given an existing Domain Group called "My Parent Group"
     And an existing Domain Group called "My Child Group" child of Domain Group "My Parent Group"
     When user "app-admin" tries to delete a Domain Group with the name "My Child Group"
     Then the system returns a result with code "Deleted"
     And Domain Group "My Child Group" does not exist as child of Domain Group "My Parent Group"

   Scenario: Deleting a Domain Group with a Domain Group pending on it
     Given an existing Domain Group called "My Parent Group"
     And an existing Domain Group called "My Child Group" child of Domain Group "My Parent Group"
     When user "app-admin" tries to delete a Domain Group with the name "My Parent Group"
     Then the system returns a result with code "Unprocessable Entity"
     And Domain Group "My Child Group" exist as child of Domain Group "My Parent Group"

   Scenario: Deleting a Domain Group with a Data Domain pending on it
     Given an existing Domain Group called "My Parent Group"
     And an existing Domain Group called "My Child Group" child of Domain Group "My Parent Group"
     And an existing Data Domain called "My Domain" child of Domain Group "My Child Group"
     When user "app-admin" tries to delete a Domain Group with the name "My Child Group"
     Then the system returns a result with code "Unprocessable Entity"
     And Domain Group "My Child Group" exist as child of Domain Group "My Parent Group"

   Scenario: Deleting a Data Domain
     Given an existing Domain Group called "My Group"
     And an existing Data Domain called "My Domain" child of Domain Group "My Group"
     When user "app-admin" tries to delete a Data Domain with the name "My Domain" child of Domain Group "My Group"
     Then the system returns a result with code "Deleted"
     And Data Domain "My Domain" does not exist as child of Domain Group "My Group"

  #  Scenario: Deleting a Data Domain with existing Business Concepts pending on them
  #    Given an existing Domain Group called "My Group"
  #    And an existing Data Domain called "My Domain" child of Domain Group "My Group"
  #    And an existing Business Concept type called "Business Term" with empty definition
  #    And an existing Business Concept in the Data Domain "My Domain" with following data:
  #     | Field             | Value                                                                   |
  #     | Type              | Business Term                                                           |
  #     | Name              | My Business Term                                                        |
  #     | Description       | This is the first description of my business term which is very simple  |
  #    When user "app-admin" tries to delete a Data Domain with the name "My Domain" child of Domain Group "My Group"
  #    Then the system returns a result with code "Unprocessable Entity"
  #    And Data Domain "My Domain" is a child of Domain Group "My Group"
