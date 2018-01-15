Feature: Super-admin Taxonomy administration
  This feature will allow a super-admin user to create all levels of taxonomy necessary to classify the content defined within the application.
  We will have data domains as containers of content and Domain Groups as grouping entities for domains or other Domain Groups

  Background:
    Given an existing user "app-admin" with the "super-admin" role in the application
    And user "app-admin" is logged in the application

  Scenario: Creating a Domain Group without any dependencies
    When user "app-admin" tries to create a Domain Group with the name "Financial Metrics"
    Then the system returns a result with code "Created"
    And the user "app-admin" is able to see the Domain Group "Financial Metrics"

  Scenario: Creating a Domain Group depending on an existing Domain Group
    Given an existing Domain Group called "Risks"
    When user "app-admin" tries to create a Domain Group with the name "Markets" depending on Domain Group "Risks"
    Then the system returns a result with code "ok"
    And the user "app-admin" is able to see the Domain Group "Markets"

  Scenario: Creating a Domain Group depending on a non existing Domain Group
    When user "app-admin" tries to create a Domain Group with the name "Markets" depending on Domain Group "Imaginary Group"
    Then the system returns a result with code "Forbidden"
    And the user "app-admin" is not able to see the Domain Group "Imaginary Group"

  Scenario: Creating a Data Domain depending on an existing Domain Group
    Given an existing Domain Group called "Risks"
    When user "app-admin" tries to create a Data Domain with the name "Operational Risk" depending on Domain Group "Risks"
    Then the system returns a result with code "ok"
    And the user "app-admin" is able to see the Data Domain "Operational Risk"

  Scenario: Creating a Data Domain depending on a non existing Domain Group
    When user "app-admin" tries to create a Data Domain with the name "Operational Risk" depending on Domain Group "Imaginary Group"
    Then the system returns a result with code "Forbidden"
    And the user "app-admin" is not able to see the Domain Group "Imaginary Group"

  Scenario: Modifying a Domain Group and seeing the new version
    Given an existing Domain Group called "Risks" with following data:
      | Description |
      | First version of Risks |
    When user "app-admin" tries to modify a Domain Group with the name "Risks" introducing following data:
      | Description |
      | Second version of Risks |
    Then the system returns a result with code "ok"
    And the user "app-admin" is able to see the Domain Group "Risks" with following data:
      | Description |
      | Second version of Riesgos |

  Scenario: Trying to modify a non existing Domain Group
    When user "app-admin" tries to modify a Domain Group with the name "Imaginary Group" introducing following data:
      | Description |
      | Second version of Imaginary Group |
    Then the system returns a result with code "Forbidden"
    And the user "app-admin" is not able to see the Domain Group "Risks"

  Scenario: Modifying a Data Domain and seeing the new version
    Given an existing Domain Group called "Risks"
    And a Data Domain called "Credit Risks" belonging to Domain Group "Risks" with following data:
      | Description |
      | First version of Credit Risks |
    When user "app-admin" tries to modify a Data Domain with the name "Credit Risks" introducing following data:
      | Description |
      | Second version of Credit Risks |
    Then the system returns a result with code "ok"
    And the user "app-admin" is able to see the Data Domain "Credit Risks" with following data:
      | Description |
      | Second version of Credit Risks |

  Scenario: Trying to modify a non existing Data Domain
    When user "app-admin" tries to modify a Data Domain with the name "Imaginary Domain" introducing following data:
      | Description |
      | Second version of Imaginary Domain |
    Then the system returns a result with code "Forbidden"
    And the user "app-admin" is not able to see the Data Domain "Imaginary Domain"

  Scenario: Deleting a Domain Group without any Group or Domain pending on it
    Given and existing Domain Group called "No-Data"
    When "app-admin" tries to delete a Domain Group with the name "No-Data"
    Then the system returns a result with code "ok"
    And the user "app-admin" is not able to see the Domain Group "Risks"

  Scenario: Deleting a Data Domain
    Given an existing Domain Group called "Risks"
    And a Data Domain called "Credit Risks" belonging to Domain Group "Risks"
    When "app-admin" tries to delete a Data Domain with the name "Credit Risks"
    Then the system returns a result with code "ok"
    And the user "app-admin" is not able to see the Data Domain "Credit Risks"

  Scenario: Deleting a non existing Data Domain
    When "app-admin" tries to delete a Data Domain with the name "Imaginary Domain"
    Then the system returns a result with code "Forbidden"
    And the user "app-admin" is not able to see the Data Domain "Imaginary Domain"

  Scenario: Deleting a Domain Group with a Data Domain pending on it
    Given an existing Domain Group called "Risks"
    And a Data Domain called "Credit Risks" belonging to Domain Group "Risks"
    When "app-admin" tries to delete a Domain Group with the name "Risks"
    Then the system returns a result with code "Forbidden"
    And the user "app-admin" is able to see the Domain Group "Risks"

  Scenario: Deleting a Domain Group with a Data Group pending on it
    Given an existing Domain Group called "Risks"
    And a Domain Group called "Markets" belonging to Domain Group "Risks"
    When "app-admin" tries to delete a Domain Group with the name "Risks"
    Then the system returns a result with code "Forbidden"
    And the user "app-admin" is able to see the Domain Group "Risks"

  Scenario: Deleting a non existing Domain Group
    When "app-admin" tries to delete a Domain Group with the name "Imaginary Group"
    Then the system returns a result with code "Forbidden"
    And the user "app-admin" is not able to see the Data Domain "Imaginary Group"
