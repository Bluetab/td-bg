Feature: Taxonomy administration
  This feature will allow to create all levels of taxonomy necessary to classify the content defined within the application.
  We will have data domains as containers of content and Domain Groups as grouping entities for domains or other Domain Groups

  Scenario Outline: Creating a Data Domain as child of an existing Domain Group by Group Manager
    Given an existing Domain Group called "My Group"
    And following users exist with the indicated role in Domain Group "My Group"
      | user      | role    |
      | watcher   | watch   |
      | creator   | create  |
      | publisher | publish |
      | admin     | admin   |
    When user "<user>" tries to create a Data Domain with the name "My Data Domain" as child of Domain Group "My Group" with following data:
       | Description |
       | First version of my Data Domain |
    Then the system returns a result with code "<result>"
    And if result <result> is "Created", user <user> is able to see the Data Domain "My Data Domain" with following data:
       | Description |
       | First version of my Data Domain |
    And if result <result> is "Created", Data Domain "My Data Domain" is a child of Domain Group "My Group"

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Unauthorized |
      | admin     | Created      |

  Scenario Outline: Creating a Domain Group as child of an existing Domain Group by Group Manager
    Given an existing Domain Group called "My Group"
    And following users exist with the indicated role in Domain Group "My Group"
      | user      | role    |
      | watcher   | watch   |
      | creator   | create  |
      | publisher | publish |
      | admin     | admin   |
    When user "<user>" tries to create a Domain Group with the name "My Child Group" as child of Domain Group "My Group" with following data:
      | Description |
      | First version of my Child Domain Group |
    Then the system returns a result with code "<result>"
    And if result <result> is "Created", user <user> is able to see the Domain Group "My Child Group" with following data:
      | Description |
      | First version of my Child Domain Group |
    And if result <result> is "Created", Domain Group "My Child Group" is a child of Domain Group "My Group"

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Unauthorized |
      | admin     | Created      |

