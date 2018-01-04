Feature: Taxonomy administration
  This feature will allow to create all levels of taxonomy necessary to classify the content defined within the application.
  We will have data domains as containers of content and Business Areas as grouping entities for domains or other Business Areas

# BUSINESS AREA CREATION
  Scenario: A super-admin user should be able to create a Business Area without any dependencies.
    Given a logged user with super-admin privileges
    When User creates a BA without dependencies
    Then new BA is created
      And succcess message is returned

  Scenario: A user without super-admin privileges should not be able to create a Business Area without any dependencies
    Given a logged user without super-admin privileges
    When User creates a BA without dependencies
    Then no BA is created
      And error message is returned

  Scenario: A BA admin should be able to create a new BA depending on this BA
    Given an existing Business Area
      And a logged user with admin privileges to this Business Area
    When User creates a new BA depending on this Business Area
    Then new BA is created
      And succcess message is returned

  Scenario: A user which is not admin of a BA should not be able to create a new BA depending on that BA
    Given an existing Business Area
      And a logged user without admin privileges to this Business Area
    When User creates a new BA depending on this Business Area
    Then no BA is created
      And error message is returned

# DATA DOMAIN CREATION
  Scenario: A BA admin should be able to create a new Data Domain on this BA
    Given an existing Business Area
      And a logged user with admin privileges to this Business Area
    When User creates a new Data Domain depending on this Business Area
    Then new Data Domain is created
      And succcess message is returned

  Scenario: A user which is not admin of a BA admin should not be able to create a Data Domain on this BA
    Given an existing Business Area
      And a logged user without admin privileges to this Business Area
    When User creates a new Data Domain depending on this Business Area
    Then no Data Domain is created
      And error message is returned

# BUSINESS AREA MODIFICATION
  Scenario: A BA admin should be able to modify his BA
    Given an existing Business Area
      And a logged user with admin privileges to this Business Area
    When User modifies this BA
    Then modifications are persisted
      And success message is returned

  Scenario: A BA admin should be able to modify any BA depending on his BA
    Given an existing Business Area with depending Business Areas
      And a logged user with admin privileges to this Business Area
    When User modifies a depending Business Area
    Then modifications are persisted
      And success message is returned

  Scenario: A user which is not admin of a BA admin should not be able to modify it
    Given an existing Business Area
      And a logged user with no admin privileges to this Business Area
    When User modifies a depending Business Area
    Then modifications are not persisted
      And error message is returned

# DATA DOMAIN MODIFICATION
  Scenario: A Data Owner should be able to modify his Domain
    Given an existing Data Domain
      And a logged user with admin privileges to this Data Domain
    When User modifies this Data Domain
    Then modifications are persisted
      And success message is returned

  Scenario: A BA admin should be able to modify any Domain depending on his BA
    Given an existing Business Area with depending Data Domains
      And a logged user with admin privileges to this Business Area
    When User modifies a depending Data Domain
    Then modifications are persisted
      And success message is returned

  Scenario: A user which is not Data Owner of a Domain should not be able to modify it
    Given an existing Data Domain
      And a logged user with no admin privileges to this Data Domain
    When User modifies a depending Business Area
    Then modifications are not persisted
      And error message is returned

#BUSINESS AREA DELETE
  Scenario: A BA admin should be able to delete the Business Area without any dependencies
    Given an existing Business Area without depending Business Areas and Data Domains
      And a logged user with admin privileges to this Business Area
    When User deletes this Business Area
    Then Business Area is deleted (logically)
      And success message is returned

  Scenario: A BA admin should not be able to delete the Business Area with any dependencies
    Given an existing Business Area with depending Business Areas and Data Domains
      And a logged user with admin privileges to this Data Domain
    When User deletes this Data Domains
    Then Business Area is not deleted
      And error message is returned

  Scenario: A user which is not business area admin should not be able to delete the business area
    Given an existing Business Area without dependencies
      And a logged user without admin privileges to this Business Area
    When User deletes this Business Area
    Then Business Area is not deleted
      And error message is returned

#DATA DOMAIN DELETE
  Scenario: A Data Owner should be able to delete a Data Domain without any associated data content
    Given an existing Data Domain without associated data content
      And a logged user with admin privileges to this Data Domain
    When User deletes this Data Domains
    Then Data Domain is deleted (logically)
      And success message is returned

  Scenario: A domain admin should not be able to delete a Data Domain with associated data content
    Given an existing Data Domain with associated data content
      And a logged user with admin privileges to this Data Domain
    When User deletes this Data Domains
    Then Data Domain is not deleted
      And error message is returned

  Scenario: A user which is not domain admin should not be able to delete a Domain
    Given an existing Data Domain without associated data content
      And a logged user without admin privileges to this Data Domain
    When User deletes this Data Domains
    Then Data Domain is not deleted
      And error message is returned
