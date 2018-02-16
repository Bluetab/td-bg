Feature: Super-admin Taxonomy administration
  This feature will allow a super-admin user to create all levels of taxonomy necessary to classify the content defined within the application.
  We will have data domains as containers of content and Domain Groups as grouping entities for domains or other Domain Groups

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

  Scenario: Deleting a Data Domain
    Given an existing Domain Group called "Risks"
    And an existing Data Domain called "Credit Risks" child of Domain Group "Risks" with following data:
      | Description |
      | First version of Credit Risks |
    When "app-admin" tries to delete a Data Domain with the name "Credit Risks"
    Then the system returns a result with code "ok"
    And the user "app-admin" is not able to see the Data Domain "Credit Risks"
