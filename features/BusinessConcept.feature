Feature: Business Concepts administration
  In this feature we cover the creation as draft, modification, publishing and deletion
  of business concepts.
  Concepts are used by the business to declare the common language that is going
  to be used by the whole organization, the rules to be followed by the data and
  the relations between concepts.
  Relation between concept types is defined at a concept type level.
  Concepts must be unique by domain and name.

  Background:
    Given a data domain called "Saldos"
    And a logged user "watcher" with the "watcher" role in the "Saldos" domain
    And a logged user "creator" with the "creation" role in the "Saldos" domain
    And a logged user "publisher" with the "publish" role in the "Saldos" domain
    And a logged user "creator2" with the "creation" role in the "Saldos" domain
    And a logged user "publisher2" with the "publish" role in the "Saldos" domain

  Scenario: A user with see privileges creates a concept
    When user tries to create a business concept with the name "Saldo Medio" in the "Saldos" domain
    Then the system returns an error with code "Forbidden"
    And the user "watcher" can't see the business concept "Saldo Medio"

  Scenario: A user with create privileges creates a concept
    When user tries to create a business concept with the name "Saldo Medio" in the "Saldos" domain
    Then the system returns a succcess with code "Created"
    And the user "creator" can see the business concept "Saldo Medio" in "draft" status
    And the user "watcher" can't see the business concept "Saldo Medio"

  Scenario: A user with create privileges tries to create a duplicated concept
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Draft" status
    When user tries to create a business concept with the name "Saldo Medio"
    Then the system returns an error with code "Forbidden"
    And the user "publisher" can't see the business concept "Saldo Medio"

  Scenario: A user with publish privileges creates a concept
    When user tries to create a business concept with the name "Saldo Medio"
    Then the system returns a succcess with code "Created"
    And the user "publisher" can see the business concept "Saldo Medio" in "draft" status
    And the user "watcher" can't see the business concept "Saldo Medio"

  Scenario: A user with publish privileges creates and publish a concept
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Draft" status
    When user "publisher" creates and publish the business concept "Saldo Medio"
    Then the system returns a succcess with code "Created"
    And the user "watcher" can see the business concept "Saldo Medio"

  Scenario: A user with see privileges tries to publish a concept
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Draft" status
    When user "watcher" tries to publish the business concept "Saldo Medio"
    Then the system returns an error with code "Forbidden"
    And the user "watcher" can't see the business concept "Saldo Medio"

  Scenario: A user with create privileges publishes a concept
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Draft" status
    When user "creator" tries to publish the business concept "Saldo Medio"
    Then the system returns an error with code "Forbidden"
    And the user "creator" can see the business concept "Saldo Medio" in "draft" status

  Scenario: A user with publish privileges publishes an existing concept in draft status
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Draft" status
    When user "publisher" tries to publish the business concept "Saldo Medio"
    Then the system returns a succcess with code "OK"
    And the user "watcher" can see the business concept "Saldo Medio"

  Scenario: A user with watch privileges tries to modify a published concept
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Published" status
    When user "watcher" tries to modify the "Saldo Medio" business concept
    Then the system returns an error with code "Forbidden"

  Scenario: A user with create privileges modifies a published concept and is not visible to normal watchers
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Published" status with the following data:
      | Description |
      | First version of saldo medio |
    When user "creator" tries to modify the "Saldo Medio" business concept with the following data:
      | Description |
      | Second version of saldo medio |
    Then the system returns a succcess with code "Created"
    And the user "watcher" can see the business concept "Saldo Medio" with the following data
      | Description | Status |
      | First version of saldo medio | Published |

  Scenario: A user with create privileges modifies a published concept and new version is visible to creators
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Published" status with the following data:
      | Description |
      | First version of saldo medio |
    When user "creator" tries to modify the "Saldo Medio" business concept with the following data:
      | Description |
      | Second version of saldo medio |
    Then the system returns a succcess with code "Created"
    And the user "creator2" can see the business concept "Saldo Medio" with the following data
      | Description | Status |
      | First version of saldo medio | Published |
      | Second version of saldo medio | Draft |

  Scenario: A user with create privileges modifies a published concept and its visible to publishers
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Published" status with the following data:
      | Description |
      | First version of saldo medio |
    When user "creator" tries to modify the "Saldo Medio" business concept with the following data:
      | Description |
      | Second version of saldo medio |
    Then the system returns a succcess with code "Created"
    And the user "publisher" can see the business concept "Saldo Medio" with the following data
      | Description | Status |
      | First version of saldo medio | Published |
      | Second version of saldo medio | Draft |

  Scenario: A user with publish privileges modifies a published concept and is not visible to watchers
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Published" status with the following data:
      | Description |
      | First version of saldo medio |
    When user "publisher" tries to modify the "Saldo Medio" business concept with the following data:
      | Description |
      | Second version of saldo medio |
    Then the system returns a succcess with code "Created"
    And the user "watcher" can see the business concept "Saldo Medio" with the following data
      | Description | Status |
      | First version of saldo medio | Published |

  Scenario: A user with publish privileges modifies a published concept and new version is visible to creators
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Published" status with the following data:
      | Description |
      | First version of saldo medio |
    When user "publisher" tries to modify the "Saldo Medio" business concept with the following data:
      | Description |
      | Second version of saldo medio |
    Then the system returns a succcess with code "Created"
    And the user "creator" can see the business concept "Saldo Medio" with the following data
      | Description | Status |
      | First version of saldo medio | Published |
      | Second version of saldo medio | Draft |

  Scenario: A user with publish privileges modifies a published concept and its visible to publishers
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Published" status with the following data:
      | Description |
      | First version of saldo medio |
    When user "publisher" tries to modify the "Saldo Medio" business concept with the following data:
      | Description |
      | Second version of saldo medio |
    Then the system returns a succcess with code "Created"
    And the user "publisher2" can see the business concept "Saldo Medio" with the following data
      | Description | Status |
      | First version of saldo medio | Published |
      | Second version of saldo medio | Draft |

  Scenario: A user with publish privileges modifies and publish a published concept and is visible to watchers
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Published" status with the following data:
      | Description |
      | First version of saldo medio |
    When user "publisher" tries to modify and publish the "Saldo Medio" business concept with the following data:
      | Description |
      | Second version of saldo medio |
    Then the system returns a succcess with code "Created"
    And the user "watcher" can see the business concept "Saldo Medio" with the following data
      | Description | Status |
      | Second version of saldo medio | Published |

  Scenario: A user with publish privileges modifies a published concept and new version is visible to creators MIRAR MIRAR
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Published" status with the following data:
      | Description |
      | First version of saldo medio |
    When user "publisher" tries to modify and publish the "Saldo Medio" business concept with the following data:
      | Description |
      | Second version of saldo medio |
    Then the system returns a succcess with code "Created"
    And the user "creator" can see the business concept "Saldo Medio" with the following data
      | Description | Status |
      | First version of saldo medio | Published |
      | Second version of saldo medio | Draft |

  Scenario: A user with publish privileges modifies a published concept and its visible to publishers
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Published" status with the following data:
      | Description |
      | First version of saldo medio |
    When user "publisher" tries to modify and publish the "Saldo Medio" business concept with the following data:
      | Description |
      | Second version of saldo medio |
    Then the system returns a succcess with code "Created"
    And the user "publisher2" can see the business concept "Saldo Medio" with the following data
      | Description | Status |
      | First version of saldo medio | Published |
      | Second version of saldo medio | Draft |

  Scenario: A user with watch privileges tries to modify a published concept
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Draft" status
    When user "watcher" tries to modify the "Saldo Medio" business concept
    Then the system returns an error with code "Forbidden"

  Scenario: A user with create privileges modifies a not published concept and is not visible to normal watchers
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Draft" status with the following data:
      | Description |
      | First version of saldo medio |
    When user "creator" tries to modify the "Saldo Medio" business concept with the following data:
      | Description |
      | Second version of saldo medio |
    Then the system returns a succcess with code "Created"
    And the user "watcher" can't see the business concept "Saldo Medio"

  Scenario: A user with create privileges modifies a not published concept and new version is visible to creators
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Draft" status with the following data:
      | Description |
      | First version of saldo medio |
    When user "creator" tries to modify the "Saldo Medio" business concept with the following data:
      | Description |
      | Second version of saldo medio |
    Then the system returns a succcess with code "Created"
    And the user "creator2" can see the business concept "Saldo Medio" with the following data
      | Description | Status |
      | Second version of saldo medio | Draft |

  Scenario: A user with create privileges modifies a not published concept and new version its visible to publishers
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Published" status with the following data:
      | Description |
      | First version of saldo medio |
    When user "creator" tries to modify the "Saldo Medio" business concept with the following data:
      | Description |
      | Second version of saldo medio |
    Then the system returns a succcess with code "Created"
    And the user "publisher" can see the business concept "Saldo Medio" with the following data
      | Description | Status |
      | Second version of saldo medio | Draft |

  Scenario: A user with publish privileges modifies a not published concept and is not visible to normal watchers
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Draft" status with the following data:
      | Description |
      | First version of saldo medio |
    When user "publisher" tries to modify the "Saldo Medio" business concept with the following data:
      | Description |
      | Second version of saldo medio |
    Then the system returns a succcess with code "Created"
    And the user "watcher" can't see the business concept "Saldo Medio"

  Scenario: A user with publish privileges modifies a not published concept and new version is visible to creators
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Draft" status with the following data:
      | Description |
      | First version of saldo medio |
    When user "publisher" tries to modify the "Saldo Medio" business concept with the following data:
      | Description |
      | Second version of saldo medio |
    Then the system returns a succcess with code "Created"
    And the user "publisher" can see the business concept "Saldo Medio" with the following data
      | Description | Status |
      | Second version of saldo medio | Draft |

  Scenario: A user with publish privileges modifies a not published concept and new version its visible to publishers
    Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Published" status with the following data:
      | Description |
      | First version of saldo medio |
    When user "creator" tries to modify the "Saldo Medio" business concept with the following data:
      | Description |
      | Second version of saldo medio |
    Then the system returns a succcess with code "Created"
    And the user "publisher2" can see the business concept "Saldo Medio" with the following data
      | Description | Status |
      | Second version of saldo medio | Draft |

  Scenario: A user with watch privileges deprecates a concept
  Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Published" status
  When user "watcher" tries to deprecate the "Saldo Medio" business concept
  Then the system returns an error with code "Forbidden"
  And the user "watcher" can see the business concept "Saldo Medio"

  Scenario: A user with create privileges deprecates a concept
  Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Published" status
  When user "watcher" tries to deprecate the "Saldo Medio" business concept
  Then the system returns an error with code "Forbidden"
  And the user "watcher" can see the business concept "Saldo Medio"

  Scenario: A user with publish privileges deprecates a concept
  Given an existing business concept with the name "Saldo Medio" in the "Saldos" domain in "Published" status
  When user "watcher" tries to deprecate the "Saldo Medio" business concept
  Then the system returns an error with code "Forbidden"
  And the user "watcher" can't see the business concept "Saldo Medio"
