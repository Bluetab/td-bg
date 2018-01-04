Feature: Business Concepts administration
  In this feature we cover the creation as draft, modification, publishing and deletion
  of business concepts.
  Concepts are used by the business to declare the common language that is going
  to be used by the whole organization, the rules to be followed by the data and
  the relations between concepts.
  Relation between concept types is defined at a concept type level.
  Concepts must be unique by type and name.

  Scenario: A user with see privileges creates a concept
    Given a logged user with the following privileges
    | privilege |
    | see |
    When user tries to create a business concept with the name "Saldo Medio"
    Then app returns an error
    And the business concept is not created

  Scenario: A user with create privileges creates a concept
  Given a user with the following privileges
  | privilege |
  | see |
  | create |
    When user tries to create a business concept with the name "Saldo Medio"
    Then app returns a succcess
    And the user can see the business concept in "draft" status

  Scenario: A user with create privileges creates a duplicated concept
    Given a logged user with create privileges
    And an existing business concept with the name "Saldo Medio"
    When user tries to create a business concept with the name "Saldo Medio"
    Then app returns an error
    And the business concept is not created

  Scenario: A user with publish privileges creates a concept
    Given a logged user with publish privileges
    When user creates a new business concept
    Then app returns a succcess
      And new concept is created in draft status

  Scenario: A user with publish privileges creates and publishes a concept
    Given a logged user with publish privileges
    When user creates and publishes a new business concept
    Then app returns a success
      And business concept is visible for user with see privileges

  Scenario: A user with see privileges publishes a concept
    Given a logged user with see privileges
      And a business concept in draft status
    When user publishes the business concept
    Then app returns an error
      And business concept is not visible for user with see privileges

  Scenario: A user with create privileges publishes a concept
    Given a logged user with create privileges
      And a business concept in draft status
    When user publishes the business concept
    Then app returns an error
      And business concept is not visible for user with see privileges

  Scenario: A user with publish privileges publishes a concept
    Given a logged user with publish privileges
      And a business concept in draft status
    When user publishes the business concept
    Then app returns a success
      And business concept is visible for user with see privileges

  Scenario: A user with see privileges modifies a published concept
    Given a logged user with see privileges
      And a business concept in published status
    When user modifies the business concept
    Then app returns an error

  Scenario: A user with create privileges modifies a published concept
    Given a logged user with create privileges
      And a business concept in published status
    When user modifies the business concept
    Then app returns a success
      And business concept old version is visible for user with see privileges
      And business concept new version is not visible for user with see privileges
      And business concept new version is visible for user with create privileges
      And business concept new version is visible for user with publish privileges

  Scenario: A user with publish privileges modifies a published concept
    Given a logged user with publish privileges
      And a business concept in published status
    When user modifies the business concept
    Then app returns a success
      And business concept old version is visible for user with see privileges
      And business concept new version is not visible for user with see privileges
      And business concept new version is visible for user with create privileges
      And business concept new version is visible for user with publish privileges

  Scenario: A user with publish privileges modifies and publishes a published concept
    Given a logged user with publish privileges
      And a business concept in published status
    When user modifies the business concept
    Then app returns a success
      And business concept new version is visible for user with see privileges
      And business concept new version is visible for user with create privileges
      And business concept new version is visible for user with publish privileges

  Scenario: A user with see privileges modifies a not published concept
    Given a logged user with see privileges
      And a business concept in draft status
    When user modifies the business concept
    Then app returns an error

  Scenario: A user with create privileges modifies a not published concept
    Given a logged user with create privileges
      And a business concept in draft status
    When user modifies the business concept
    Then app returns a success
      And business concept new version is not visible for user with see privileges
      And business concept new version is visible for user with create privileges
      And business concept new version is visible for user with publish privileges

  Scenario: A user with publish privileges modifies a not published concept
    Given a logged user with publish privileges
      And a business concept in draft status
    When user modifies the business concept
    Then app returns a success
      And business concept new version is not visible for user with see privileges
      And business concept new version is visible for user with create privileges
      And business concept new version is visible for user with publish privileges

  Scenario: A user with see privileges deprecates a concept
    Given a logged user with see privileges
      And a business concept in published status
    When user deprecates the business concept
    Then app returns an error
      And business concept is visible for user with see privileges

  Scenario: A user with create privileges deprecates a concept
    Given a logged user with create privileges
      And a business concept in published status
    When user deprecates the business concept
    Then app returns an error
      And business concept is visible for user with see privileges

  Scenario: A user with publish privileges deprecates a concept
    Given a logged user with publish privileges
      And a business concept in published status
    When user deprecates the business concept
    Then app returns a success
      And business concept is not visible for user with see privileges

  Scenario: A user with see privileges queries a draft concept
    Given a logged user with see privileges
      And a business concept in draft status
    When user queries the business concept
    Then app returns an error

  Scenario: A user with create privileges queries a draft concept
    Given a logged user with see privileges
      And a business concept in draft status
    When user queries the business concept
    Then app returns a succcess
      And app returns all Business Concept data

  Scenario: A user with publish privileges queries a draft concept
    Given a logged user with see privileges
      And a business concept in draft status
    When user queries the business concept
    Then app returns a succcess
      And app returns all Business Concept data

  Scenario: A user with see privileges queries a published concept
    Given a logged user with see privileges
      And a business concept in published status
    When user queries the business concept
    Then app returns a succcess
      And app returns all Business Concept data

  Scenario: A user with create privileges queries a published concept
    Given a logged user with create privileges
      And a business concept in published status
    When user queries the business concept
    Then app returns a succcess
      And app returns all Business Concept data

  Scenario: A user with publish privileges queries a published concept
    Given a logged user with publish privileges
      And a business concept in published status
    When user queries the business concept
    Then app returns a succcess
      And app returns all Business Concept data

  Scenario: A user with see privileges queries a concept with a published
            version and a modified draft version
    Given a logged user with see privileges
      And a business concept with a published version and a draft modifications
    When user queries the business concept
    Then app returns a succcess
      And app returns all business concept data for published version

  Scenario: A user with create privileges queries a concept with a published
            version and a modified draft version
    Given a logged user with create privileges
      And a business concept with a published version and a draft modifications
    When user queries the business concept
    Then app returns a succcess
      And app returns all business concept data for draft version

  Scenario: A user with publish privileges queries a concept with a published
            version and a modified draft version
    Given a logged user with publish privileges
      And a business concept with a published version and a draft modifications
    When user queries the business concept
    Then app returns a succcess
      And app returns all business concept data for draft version
