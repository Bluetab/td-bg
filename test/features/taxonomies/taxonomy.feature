Feature: Taxonomy administration
  This feature will allow to create all levels of taxonomy necessary to classify the content defined within the application.

  Scenario Outline: Creating a Domain as child of an existing Domain by Group Manager
    Given an existing Domain called "My Domain Parent"
    And following users exist with the indicated role in Domain "My Domain Parent"
      | user      | role    |
      | watcher   | watch   |
      | creator   | create  |
      | publisher | publish |
      | admin     | admin   |
    When user "<user>" tries to create a Domain with the name "My Domain" as child of Domain "My Domain Parent" with following data:
       | Description |
       | First version of my Domain |
    Then the system returns a result with code "<result>"
    And if result <result> is "Created", user "<user>" is able to see the Domain "My Domain" with following data:
       | Description |
       | First version of my Domain |
    And if result <result> is "Created", Domain "My Domain" is a child of Domain "My Domain Parent"

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Unauthorized |
      | admin     | Created      |

  Scenario Outline: Creating a Domain as child of an existing Domain by Group Manager
    Given an existing Domain called "My Parent Domain"
    And following users exist with the indicated role in Domain "My Parent Domain"
      | user      | role    |
      | watcher   | watch   |
      | creator   | create  |
      | publisher | publish |
      | admin     | admin   |
    When user "<user>" tries to create a Domain with the name "My Child Domain" as child of Domain "My Parent Domain" with following data:
      | Description |
      | First version of my Child Domain |
    Then the system returns a result with code "<result>"
    And if result <result> is "Created", user "<user>" is able to see the Domain "My Child Domain" with following data:
      | Description |
      | First version of my Child Domain |
    And if result <result> is "Created", Domain "My Child Domain" is a child of Domain "My Parent Domain"

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Unauthorized |
      | admin     | Created      |

  Scenario Outline: Modifying a Domain and seeing the new version by Group Manager
    Given an existing Domain called "My Parent Domain"
    And an existing Domain called "My Child Domain" child of Domain "My Parent Domain" with following data:
      | Description |
      | First version of Child Domain |
    And following users exist with the indicated role in Domain "My Child Domain"
      | user      | role    |
      | watcher   | watch   |
      | creator   | create  |
      | publisher | publish |
      | admin     | admin   |
    When user "<user>" tries to modify a Domain with the name "My Child Domain" introducing following data:
      | Description |
      | Second version of My Child Domain |
    Then the system returns a result with code "<result>"
    And if result <result> is "Ok", user "<user>" is able to see the Domain "My Child Domain" with following data:
      | Description |
      | Second version of My Child Domain |
    And if result <result> is not "Ok", user "<user>" is able to see the Domain "My Child Domain" with following data:
      | Description |
      | First version of Child Domain |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Unauthorized |
      | admin     | Ok           |

  Scenario Outline: Modifying a Domain and seeing the new version by Domain Manager
    Given an existing Domain called "My Parent Domain"
    And an existing Domain called "My Child Domain" child of Domain "My Parent Domain" with following data:
      | Description |
      | First version of My Child Domain |
    And following users exist with the indicated role in Domain "My Child Domain"
      | user      | role    |
      | watcher   | watch   |
      | creator   | create  |
      | publisher | publish |
      | admin     | admin   |
    When user "<user>" tries to modify a Domain with the name "My Child Domain" introducing following data:
      | Description |
      | Second version of My Child Domain |
    Then the system returns a result with code "<result>"
    And if result <result> is "Ok", user "<user>" is able to see the Domain "My Child Domain" with following data:
      | Description |
      | Second version of My Child Domain |
    And if result <result> is not "Ok", user "<user>" is able to see the Domain "My Child Domain" with following data:
      | Description |
      | First version of My Child Domain |

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Unauthorized |
      | admin     | Ok           |

  Scenario Outline: Deleting a Domain without any Group or Domain pending on it by Group Manager
    Given an existing Domain called "My Parent Group"
    And an existing Domain called "My Child Domain" child of Domain "My Parent Group"
    And following users exist with the indicated role in Domain "My Child Domain"
      | user      | role    |
      | watcher   | watch   |
      | creator   | create  |
      | publisher | publish |
      | admin     | admin   |
    When user "<user>" tries to delete a Domain with the name "My Child Domain"
    Then the system returns a result with code "<result>"
    And if result <result> is "Deleted", Domain "My Child Domain" does not exist as child of Domain "My Parent Group"
    And if result <result> is not "Deleted", Domain "My Child Domain" is a child of Domain "My Parent Group"

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Unauthorized |
      | admin     | Deleted      |

  Scenario Outline: Deleting a Domain without any Business Concept by Group Manager
    Given an existing Domain called "My Parent Domain"
    And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
    And following users exist with the indicated role in Domain "My Child Domain"
      | user      | role    |
      | watcher   | watch   |
      | creator   | create  |
      | publisher | publish |
      | admin     | admin   |
    When user "<user>" tries to delete a Domain with the name "My Child Domain"
    Then the system returns a result with code "<result>"
    And if result <result> is "Deleted", Domain "My Child Domain" does not exist as child of Domain "My Parent Domain"
    And if result <result> is not "Deleted", Domain "My Child Domain" is a child of Domain "My Parent Domain"

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Unauthorized |
      | admin     | Deleted      |
