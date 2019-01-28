Background:
  Given an existing Domain called "My Parent Group"

Scenario: Upload business concepts
  Given an existing Domain called "My Child Domain" child of Domain "My Parent Group"
  And an existing Domain called "My Domain" child of Domain "My Child Domain"
  And an existing Business Concept type called "Business_Term" with following definition:
   | Field    | Max Size | Values                                        | Cardinality | Default Value | Group      |
   | Formula  | 100      |                                               | ?           |               | General    |
   | Values   | 100      | Date, Numeric, Amount, Text                   | ?           |               | Functional |
  When "app-admin" uploads business concepts with the following data:
    | template      | domain          | name   | description | Formula | Values |
    | Business_Term | My Parent Group | First  | First Term  | one     | some   |
    | Business_Term | My Child Domain | Second | Second Term | two     | funny  |
    | Business_Term | My Domain       | Third  | Third Term  | three   | values |
  Then the system returns a result with code "Ok"
  Then "app-admin" is able to view the following uploaded business concepts:
    | template      | domain          | name   | description | Formula | Values |
    | Business_Term | My Parent Group | First  | First Term  | one     | some   |
    | Business_Term | My Child Domain | Second | Second Term | two     | funny  |
    | Business_Term | My Domain       | Third  | Third Term  | three   | values |
