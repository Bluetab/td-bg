Scenario Outline: History of changes in Business Glossary
  Given an existing Domain called "My Parent Domain"
  And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
  And an existing Domain called "My Domain" child of Domain "My Child Domain"
  And following users exist with the indicated role in Domain "My Domain"
    | user      | role    |
    | watcher   | watch   |
    | creator   | create  |
    | publisher | publish |
    | admin     | admin   |
  And an existing Business Concept type called "Business Term" with empty definition
  And an existing Business Concept of type "Business Term" in the Domain "My Domain" with following data:
    | Field             | Value                                             |
    | Type              | Business Term                                     |
    | Name              | My Business Term                                  |
    | Description       | This is the first description of my business term |
  And the status of business concept with name "My Business Term" of type "Business Term" is set to "pending_approval" for version 4
  When <user> tries to query history for a business concept with name "My Business Term" of type "Business Term"
  Then if <user> is "watcher" the system returns following data:
    | name             | type          | description                                        | Last Modification | Last User   | version | status           |
    | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 3       | published        |
    | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 2       | versioned        |
    | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 1       | versioned        |
  Then if <user> is "creator" the system returns following data:
    | name             | type          | description                                        | Last Modification | Last User   | version | status           |
    | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 3       | published        |
    | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 2       | versioned        |
    | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 1       | versioned        |
  Then if <user> is "publisher" the system returns following data:
    | name             | type          | description                                        | Last Modification | Last User   | version | status           |
    | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 4       | pending_approval |
    | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 3       | published        |
    | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 2       | versioned        |
    | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 1       | versioned        |
  Then if <user> is "admin" the system returns following data:
    | name             | type          | description                                        | Last Modification | Last User   | version | status           |
    | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 4       | pending_approval |
    | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 3       | published        |
    | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 2       | versioned        |
    | My Business Term | Business Term | This is the first description of my business term  | Some timestamp    | app-admin   | 1       | versioned        |

  Examples:
    | user      |
    | watcher   |
    | creator   |
    | publisher |
    | admin     |