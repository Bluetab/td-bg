Background:
  Given an existing Domain called "My Parent Group"

Scenario: Upload business concepts
  Given an existing Domain called "My Child Domain" child of Domain "My Parent Group"
  And an existing Domain called "My Domain" child of Domain "My Child Domain"
  And an existing Business Concept type called "Business Term" with following definition:
   | Field    | Format        | Max Size | Values                                        | Mandatory | Default Value | Group      |
   | Formula  | string        | 100      |                                               |    NO     |               | General    |
   | Format   | list          |          | Date, Numeric, Amount, Text                   |    NO     |               | General    |
   # | Values   | variable_list | 100      |                                               |    NO     |               | Functional |
  When "app-admin" uploads business concepts with the following data:
    | template      | domain          | name   | description | Formula | Format  | Values            |
    | Business Term | My Parent Group | First  | First Term  | one     | Date    | some,values       |
    | Business Term | My Child Domain | Second | Second Term | two     | Numeric | some,funny,values |
    | Business Term | My Domain       | Third  | Third Term  | three   | Amount  | some,great,values |
  Then the system returns a result with code "Ok"
  Then "app-admin" is able to view the following uploaded business concepts:
    | template      | domain          | name   | description | Formula | Format  | Values            |
    | Business Term | My Parent Group | First  | First Term  | one     | Date    | some,values       |
    | Business Term | My Child Domain | Second | Second Term | two     | Numeric | some,funny,values |
    | Business Term | My Domain       | Third  | Third Term  | three   | Amount  | some,great,values |
