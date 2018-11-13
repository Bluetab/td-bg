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
    And if result <result> is "No Content", Domain "My Child Domain" does not exist as child of Domain "My Parent Group"
    And if result <result> is not "No Content", Domain "My Child Domain" is a child of Domain "My Parent Group"

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Unauthorized |
      | admin     | No Content      |

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
    And if result <result> is "No Content", Domain "My Child Domain" does not exist as child of Domain "My Parent Domain"
    And if result <result> is not "No Content", Domain "My Child Domain" is a child of Domain "My Parent Domain"

    Examples:
      | user      | result       |
      | watcher   | Unauthorized |
      | creator   | Unauthorized |
      | publisher | Unauthorized |
      | admin     | No Content      |

  Scenario Outline: Deleting a Domain with some Domain Child
    Given an existing Domain called "My Parent Domain"
    And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
    And following users exist with the indicated role in Domain "My Parent Domain"
      | user      | role    |
      | admin     | admin   |
    When user "<user>" tries to delete a Domain with the name "My Parent Domain"
    Then the system returns a result with code "<result>"
    And if result <result> is not "No Content", Domain "My Child Domain" is a child of Domain "My Parent Domain"
    And a error message with key "ETD001" and alias "error.existing.domain" is retrieved

    Examples:
      | user      | result                    |
      | admin     | Unprocessable Entity      |

  Scenario Outline: Deleting a Domain with some Business Concept
    Given an existing Domain called "My Parent Domain"
    And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
    And an existing Business Concept type called "Business_Term" with empty definition
    And an existing Business Concept in the Domain "My Child Domain" with following data:
      | Field             | Value                                                                   |
      | Type              | Business_Term                                                           |
      | Name              | My Business Term                                                        |
      | Description       | This is the first description of my business term which is very simple  |
    And following users exist with the indicated role in Domain "My Parent Domain"
      | user      | role    |
      | admin     | admin   |
    When user "<user>" tries to delete a Domain with the name "My Child Domain"
    Then the system returns a result with code "<result>"
    And if result <result> is not "No Content", Domain "My Child Domain" is a child of Domain "My Parent Domain"
    And a error message with key "ETD002" and alias "error.existing.business.concept" is retrieved

    Examples:
      | user      | result                    |
      | admin     | Unprocessable Entity      |
