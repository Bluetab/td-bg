Scenario: list of Business Concept types
  Given an existing Business Concept type called "Business_Concept_Type_1" with empty definition
  And an existing Business Concept type called "Business_Concept_Type_2" with empty definition
  And an existing Business Concept type called "Business_Concept_Type_3" with empty definition
  And an existing Business Concept type called "Business_Concept_Type_4" with empty definition
  When "app-admin" tries to get the list of business concept types
  Then user "app-admin" is able to see following list of Business Concept Types
    | type_name               |
    | Business_Concept_Type_1 |
    | Business_Concept_Type_2 |
    | Business_Concept_Type_3 |
    | Business_Concept_Type_4 |

Scenario: List business concept type fields
Given an existing Business Concept type called "Business_Term" with following definition:
  | Field            | Format        | Max Size | Values                                       | Mandatory | Default Value | Group      |
  | Formula          | string        | 100      |                                              |    NO     |               | General    |
  | Format           | list          |          | Date, Numeric, Amount, Text                  |    YES    |               | General    |
  | List of Values   | variable_list | 100      |                                              |    NO     |               | Functional |
  | Sensitive Data   | list          |          | N/A, Personal Data, Related to personal Data |    NO     | N/A           | Functional |
  | Update Frequency | list          |          | Not defined, Daily, Weekly, Monthly, Yearly  |    NO     | Not defined   | General    |
  | Related Area     | string        | 100      |                                              |    NO     |               | Functional |
  | Default Value    | string        | 100      |                                              |    NO     |               | General    |
  | Additional Data  | string        | 500      |                                              |    NO     |               | Functional |
When "app-admin" tries to get the list of fields of business concept type "Business_Term"
Then user "app-admin" is able to see following list of Business Concept Type Fields
  | Field            | Format        | Max Size | Values                                       | Mandatory | Default Value | Group      |
  | Formula          | string        | 100      |                                              |    NO     |               | General    |
  | Format           | list          |          | Date, Numeric, Amount, Text                  |    YES    |               | General    |
  | List of Values   | variable_list | 100      |                                              |    NO     |               | Functional |
  | Sensitive Data   | list          |          | N/A, Personal Data, Related to personal Data |    NO     | N/A           | Functional |
  | Update Frequency | list          |          | Not defined, Daily, Weekly, Monthly, Yearly  |    NO     | Not defined   | General    |
  | Related Area     | string        | 100      |                                              |    NO     |               | Functional |
  | Default Value    | string        | 100      |                                              |    NO     |               | General    |
  | Additional Data  | string        | 500      |                                              |    NO     |               | Functional |
