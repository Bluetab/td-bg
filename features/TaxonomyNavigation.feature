Feature: Taxonomy Navigation allows to navigate throw all the Domaing Groups and Data Domains in order to get
         the corresponding Business Concepts

  Scenario: List of all Domain Groups without parent
    Given an existing Domain Group called "My Parent Group" with following data:
      | Description |
      | First version of My Parent Group |
    Given an existing Domain Group called "My Second Parent Group" with following data:
      | Description |
      | First version of My Second Parent Group |
    Given an existing Domain Group called "My Third Parent Group" with following data:
      | Description |
      | First version of My Third Parent Group |
    And user "app-admin" is logged in the application with password "mypass"
    When user tries to query a list of all root Domain Groups
    Then user sees following list:
      | Domain Group           | Description                             |
      | My Parent Group        | First version of My Parent Group        |
      | My Second Parent Group | First version of My Second Parent Group |
      | My Third Parent Group  | First version of My Third Parent Group  |

  Scenario: List of all Domain Groups that are child of a certain Domain Group
    Given an existing Domain Group called "My Parent Group"
    And an existing Domain Group called "My Child Group" child of Domain Group "My Parent Group" with following data:
      | Description |
      | First version of My Child Group |
    And an existing Domain Group called "My Second Child Group" child of Domain Group "My Parent Group" with following data:
      | Description |
      | First version of My Second Child Group |
    And an existing Domain Group called "My Third Child Group" child of Domain Group "My Parent Group" with following data:
      | Description |
      | First version of My Third Child Group |
    And an existing Domain Group called "My Fourth Child Group" child of Domain Group "My Parent Group" with following data:
      | Description |
      | First version of My Fourth Child Group |
    And user "app-admin" is logged in the application with password "mypass"
    When user tries to query a list of all Domain Groups children of Domain Group "My Parent Group"
    Then user sees following list:
      | Domain Group           | Description                             |
      | My Child Group         | First version of My Child Group         |
      | My Second Child Group  | First version of My Second Child Group  |
      | My Third Child Group   | First version of My Third Child Group   |
      | My Fourth Child Group  | First version of My Fourth Child Group  |

  Scenario: List of all Data Domains that are child of a certain Domain Group
    Given an existing Domain Group called "My Parent Group"
    And an existing Domain Group called "My Child Group" child of Domain Group "My Parent Group"
    And an existing Data Domain called "My Data Domain" child of Domain Group "My Child Group" with following data:
      | Description |
      | First version of My Data Domain |
    And an existing Data Domain called "My Second Data Domain" child of Domain Group "My Child Group" with following data:
      | Description |
      | First version of My Second Data Domain |
    And an existing Data Domain called "My Third Data Domain" child of Domain Group "My Child Group" with following data:
      | Description |
      | First version of My Third Data Domain |
    And an existing Data Domain called "My Fourth Data Domain" child of Domain Group "My Child Group" with following data:
      | Description |
      | First version of My Fourth Data Domain |
    And user "app-admin" is logged in the application with password "mypass"
    When user tries to query a list of all Data Domains children of Domain Group "My Child Group"
    Then user sees following list:
      | Data Domain            | Description                             |
      | My Child Group         | First version of My Data Domain         |
      | My Second Child Group  | First version of My Second Data Domain  |
      | My Third Child Group   | First version of My Third Data Domain   |
      | My Fourth Child Group  | First version of My Fourth Data Domain  |

  Scenario: List of all business concepts child of a Data Domain
    Given an existing Domain Group called "My Parent Group"
    And an existing Domain Group called "My Child Group" child of Domain Group "My Parent Group"
    And an existing Data Domain called "My Data Domain" child of Domain Group "My Child Group" with following data:
      | Description |
      | First version of My Data Domain |
    And an existing Business Concept type called "Business Term" with empty definition
    And an existing Business Concept type called "Policy" with empty definition
    And an existing Business Concept with following data:
     | Type          | Name             | Description                                       |
     | Business Term | My Business Term | This is the first description of my business term |
    And an existing Business Concept with following data:
     | Type          | Name                   | Description                                              |
     | Business Term | My Seond Business Term | This is the first description of my second business term |
    And an existing Business Concept with following data:
     | Type          | Name                   | Description                                              |
     | Business Term | My Third Business Term | This is the first description of my third business term  |
    And an existing Business Concept with following data:
     | Type          | Name                   | Description                                      |
     | Policy        | My First Policy        | This is the first description of my First Policy |
    And user "app-admin" is logged in the application with password "mypass"
    When user tries to query a list of all Business Concepts children of Data Domain "My Data Domain"
    Then user sees following list:
      | Name                    | Type           | Description                                              |
      | My Business Term        | Business Term  | This is the first description of my business term        |
      | My Second Business Term | Business Term  | This is the first description of my second business term |
      | My Third Business Term  | Business Term  | This is the first description of my third business term  |
      | My First Policy         | Policy         | This is the first description of my First Policy         |
