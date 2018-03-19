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
    And an existing Domain Group called "My Child Group" child of Domain Group "My Parent Group" with following data:
      | Description |
      | First version of My Child Group |
    When user "app-admin" tries to query a list of all Domain Groups without parent
    Then user sees following list:
      | name                   | description                             |
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
    When user "app-admin" tries to query a list of all Domain Groups children of Domain Group "My Parent Group"
    Then user sees following list:
      | name                   | description                             |
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
    When user "app-admin" tries to query a list of all Data Domains children of Domain Group "My Child Group"
    Then user sees following list:
      | name                   | description                             |
      | My Data Domain         | First version of My Data Domain         |
      | My Second Data Domain  | First version of My Second Data Domain  |
      | My Third Data Domain   | First version of My Third Data Domain   |
      | My Fourth Data Domain  | First version of My Fourth Data Domain  |

   Scenario: List of all business concepts child of a Data Domain
     Given an existing Domain Group called "My Parent Group"
     And an existing Domain Group called "My Child Group" child of Domain Group "My Parent Group"
     And an existing Data Domain called "My Data Domain" child of Domain Group "My Child Group"
     And an existing Data Domain called "My Second Data Domain" child of Domain Group "My Child Group"
     And an existing Business Concept type called "Business Term" with empty definition
     And an existing Business Concept type called "Policy" with empty definition
     And an existing Business Concept of type "Business Term" in the Data Domain "My Data Domain" with following data:
       | Field             | Value                                                              |
       | Type              | Business Term                                                      |
       | Name              | My First Business Concept of this type                             |
       | Description       | This is the first description of my first business term            |
     And an existing Business Concept of type "Business Term" in the Data Domain "My Data Domain" with following data:
       | Field             | Value                                                              |
       | Type              | Business Term                                                      |
       | Name              | My Second Business Concept of this type                            |
       | Description       | This is the first description of my second business term           |
     And an existing Business Concept of type "Policy" in the Data Domain "My Data Domain" with following data:
       | Field             | Value                                                              |
       | Type              | Policy                                                             |
       | Name              | My First Business Concept of this type                             |
       | Description       | This is the first description of my first policy                   |
     And an existing Business Concept of type "Policy" in the Data Domain "My Second Data Domain" with following data:
       | Field             | Value                                                              |
       | Type              | Policy                                                             |
       | Name              | My Second Business Concept of this type                            |
       | Description       | This is the first description of my second policy                  |
     When user "app-admin" tries to query a list of all Business Concepts children of Data Domain "My Data Domain"
     Then user sees following business concepts list:
       | name                                    | type           | status | description                                              |
       | My First Business Concept of this type  | Business Term  | draft  | This is the first description of my first business term  |
       | My Second Business Concept of this type | Business Term  | draft  | This is the first description of my second business term |
       | My First Business Concept of this type  | Policy         | draft  | This is the first description of my first policy         |

     Scenario: List Domain Groups and Data Domains structure
       Given an existing Domain Group called "My Root Group"
       And an existing Domain Group called "My Root Group 2"
       And an existing Domain Group called "My Child Group" child of Domain Group "My Root Group"
       And an existing Data Domain called "My Data Domain" child of Domain Group "My Child Group"
       And an existing Data Domain called "My Second Data Domain" child of Domain Group "My Child Group"
       When user "app-admin" tries to list taxonomy tree"
