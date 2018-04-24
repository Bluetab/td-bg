Feature: Taxonomy Navigation allows to navigate throw all the Domains in order to get
         the corresponding Business Concepts

  Scenario: List of all Domains without parent
    Given an existing Domain called "My Parent Domain" with following data:
      | Description |
      | First version of My Parent Domain |
    Given an existing Domain called "My Second Parent Domain" with following data:
      | Description |
      | First version of My Second Parent Domain |
    Given an existing Domain called "My Third Parent Domain" with following data:
      | Description |
      | First version of My Third Parent Domain |
    And an existing Domain called "My Child Domain" child of Domain "My Parent Domain" with following data:
      | Description |
      | First version of My Child Domain |
    When user "app-admin" tries to query a list of all Domains without parent
    Then user sees following list:
      | name                   | description                             |
      | My Parent Domain        | First version of My Parent Domain        |
      | My Second Parent Domain | First version of My Second Parent Domain |
      | My Third Parent Domain  | First version of My Third Parent Domain  |

  Scenario: List of all Domains that are child of a certain Domain
    Given an existing Domain called "My Parent Domain"
    And an existing Domain called "My Child Domain" child of Domain "My Parent Domain" with following data:
      | Description |
      | First version of My Child Domain |
    And an existing Domain called "My Second Child Domain" child of Domain "My Parent Domain" with following data:
      | Description |
      | First version of My Second Child Domain |
    And an existing Domain called "My Third Child Domain" child of Domain "My Parent Domain" with following data:
      | Description |
      | First version of My Third Child Domain |
    And an existing Domain called "My Fourth Child Domain" child of Domain "My Parent Domain" with following data:
      | Description |
      | First version of My Fourth Child Domain |
    When user "app-admin" tries to query a list of all Domains children of Domain "My Parent Domain"
    Then user sees following list:
      | name                    | description                              |
      | My Child Domain         | First version of My Child Domain         |
      | My Second Child Domain  | First version of My Second Child Domain  |
      | My Third Child Domain   | First version of My Third Child Domain   |
      | My Fourth Child Domain  | First version of My Fourth Child Domain  |

   Scenario: List of all business concepts child of a Domain
     Given an existing Domain called "My Parent Domain"
     And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
     And an existing Domain called "My Domain" child of Domain "My Child Domain"
     And an existing Domain called "My Second Domain" child of Domain "My Child Domain"
     And an existing Business Concept type called "Business Term" with empty definition
     And an existing Business Concept type called "Policy" with empty definition
     And an existing Business Concept of type "Business Term" in the Domain "My Domain" with following data:
       | Field             | Value                                                              |
       | Type              | Business Term                                                      |
       | Name              | My First Business Concept of this type                             |
       | Description       | This is the first description of my first business term            |
     And an existing Business Concept of type "Business Term" in the Domain "My Domain" with following data:
       | Field             | Value                                                              |
       | Type              | Business Term                                                      |
       | Name              | My Second Business Concept of this type                            |
       | Description       | This is the first description of my second business term           |
     And an existing Business Concept of type "Policy" in the Domain "My Domain" with following data:
       | Field             | Value                                                              |
       | Type              | Policy                                                             |
       | Name              | My First Business Concept of this type                             |
       | Description       | This is the first description of my first policy                   |
     And an existing Business Concept of type "Policy" in the Domain "My Second Domain" with following data:
       | Field             | Value                                                              |
       | Type              | Policy                                                             |
       | Name              | My Second Business Concept of this type                            |
       | Description       | This is the first description of my second policy                  |
     When user "app-admin" tries to query a list of all Business Concepts children of Domain "My Domain"
     Then user sees following business concepts list:
       | name                                    | type           | status | description                                              |
       | My First Business Concept of this type  | Business Term  | draft  | This is the first description of my first business term  |
       | My Second Business Concept of this type | Business Term  | draft  | This is the first description of my second business term |
       | My First Business Concept of this type  | Policy         | draft  | This is the first description of my first policy         |

     Scenario: List Domains structure
       Given an existing Domain called "My Root Domain"
       And an existing Domain called "My Root Domain 2"
       And an existing Domain called "My Child Domain" child of Domain "My Root Domain"
       And an existing Domain called "My Child Domain child" child of Domain "My Child Domain"
       And an existing Domain called "My Domain" child of Domain "My Child Domain"
       And an existing Domain called "My Second Domain" child of Domain "My Child Domain"
       When user "app-admin" tries to list taxonomy tree"
       Then user sees following tree structure:
         """
          [
            {
              "name": "My Root Domain",
              "type": null,
              "description": null,
              "children": [
                {
                  "name": "My Child Domain",
                  "type": null,
                  "description": null,
                  "children": [
                    {
                      "name": "My Child Domain child",
                      "type": null,
                      "description": null,
                      "children": []
                    },
                    {
                      "name": "My Domain",
                      "type": null,
                      "description": null,
                      "children": []
                    },
                    {
                      "name": "My Second Domain",
                      "type": null,
                      "description": null,
                      "children": []
                    }
                  ]
                }
              ]
            },
            {
              "name": "My Root Domain 2",
              "type": null,
              "description": null,
              "children": []
            }
          ]
         """


  Scenario: List of all business concepts child of a Domain
    Given an existing Domain called "My Parent Domain"
    And an existing Domain called "My Child Domain" child of Domain "My Parent Domain"
    And an existing Domain called "My Domain" child of Domain "My Child Domain"
    And an existing Domain called "My Second Domain" child of Domain "My Child Domain"
    And an existing Business Concept type called "Business Term" with empty definition
    And an existing Business Concept type called "Policy" with empty definition
    And an existing Business Concept of type "Business Term" in the Domain "My Domain" with following data:
      | Field             | Value                                                              |
      | Type              | Business Term                                                      |
      | Name              | My First Business Concept of this type                             |
      | Description       | This is the first description of my first business term            |
    And an existing Business Concept of type "Business Term" in the Domain "My Domain" with following data:
      | Field             | Value                                                              |
      | Type              | Business Term                                                      |
      | Name              | My Second Business Concept of this type                            |
      | Description       | This is the first description of my second business term           |
    And an existing Business Concept of type "Policy" in the Domain "My Domain" with following data:
      | Field             | Value                                                              |
      | Type              | Policy                                                             |
      | Name              | My First Business Concept of this type                             |
      | Description       | This is the first description of my first policy                   |
    And an existing Business Concept of type "Policy" in the Domain "My Second Domain" with following data:
      | Field             | Value                                                              |
      | Type              | Policy                                                             |
      | Name              | My Second Business Concept of this type                            |
      | Description       | This is the first description of my second policy                  |
    When user "app-admin" tries to query a list of all Business Concepts children of Domain "My Domain"
    Then user sees following business concepts list:
      | name                                    | type           | status | description                                              |
      | My First Business Concept of this type  | Business Term  | draft  | This is the first description of my first business term  |
      | My Second Business Concept of this type | Business Term  | draft  | This is the first description of my second business term |
      | My First Business Concept of this type  | Policy         | draft  | This is the first description of my first policy         |

  Scenario: List Big Domain structure
    Given an existing Domain called "Domain 1"
    And an existing Domain called "Domain 2"
    And an existing Domain called "Domain 3"
    And an existing Domain called "Domain 1.1" child of Domain "Domain 1"
    And an existing Domain called "Domain 1.1.1" child of Domain "Domain 1.1"
    And an existing Domain called "Domain 1.1.1.1" child of Domain "Domain 1.1.1"
    And an existing Domain called "Domain 1.1.1.2" child of Domain "Domain 1.1.1"
    And an existing Domain called "Domain 1.1.1.2.1" child of Domain "Domain 1.1.1.2"
    And an existing Domain called "Domain 1.1.1.2.1.1" child of Domain "Domain 1.1.1.2.1"
    And an existing Domain called "Domain 3.1" child of Domain "Domain 3"
    And an existing Domain called "Domain 3.2" child of Domain "Domain 3"
    And an existing Domain called "Domain 3.3" child of Domain "Domain 3"
    And an existing Domain called "Domain 3.4" child of Domain "Domain 3"
    And an existing Domain called "Domain 3.5" child of Domain "Domain 3"
    And an existing Domain called "Domain 3.2.1" child of Domain "Domain 3.2"
    And an existing Domain called "Domain 3.2.2" child of Domain "Domain 3.2"
    And an existing Domain called "Domain 3.5.1" child of Domain "Domain 3.5"
    And an existing Domain called "Domain 3.5.1.1" child of Domain "Domain 3.5.1"
    And an existing Domain called "Domain 3.5.1.2" child of Domain "Domain 3.5.1"
    And an existing Domain called "Domain 2.1" child of Domain "Domain 2"
    And an existing Domain called "Domain 2.2" child of Domain "Domain 2"
    And an existing Domain called "Domain 3.5.1.1.1" child of Domain "Domain 3.5.1.1"
    And an existing Domain called "Domain 1.1.1.2.1.1.1" child of Domain "Domain 1.1.1.2.1.1"
    And an existing Domain called "Domain 1.1.1.2.1.1.2" child of Domain "Domain 1.1.1.2.1.1"
    And an existing Domain called "Domain 1.1.1.2.1.1.3" child of Domain "Domain 1.1.1.2.1.1"
    And an existing Domain called "Domain 1.1.1.2.1.1.4" child of Domain "Domain 1.1.1.2.1.1"
    And an existing Domain called "Domain 1.1.1.2.1.1.5" child of Domain "Domain 1.1.1.2.1.1"
    When user "app-admin" tries to list taxonomy tree"
    Then user sees following tree structure:
         """
          [
            {
              "children": [
                {
                  "children": [
                    {
                      "children": [
                        {
                          "children": [],
                          "type": null,
                          "description": null,
                          "name": "Domain 1.1.1.1"
                        },
                        {
                          "children": [
                            {
                              "children": [
                                {
                                  "children": [
                                    {
                                      "children": [],
                                      "type": null,
                                      "description": null,
                                      "name": "Domain 1.1.1.2.1.1.1"
                                    },
                                    {
                                      "children": [],
                                      "type": null,
                                      "name": "Domain 1.1.1.2.1.1.2",
                                      "description": null
                                    },
                                    {
                                      "children": [],
                                      "type": null,
                                      "description": null,
                                      "name": "Domain 1.1.1.2.1.1.3"
                                    },
                                    {
                                      "children": [],
                                      "type": null,
                                      "description": null,
                                      "name": "Domain 1.1.1.2.1.1.4"
                                    },
                                    {
                                      "children": [],
                                      "type": null,
                                      "description": null,
                                      "name": "Domain 1.1.1.2.1.1.5"
                                    }
                                  ],
                                  "type": null,
                                  "description": null,
                                  "name": "Domain 1.1.1.2.1.1"
                                }
                              ],
                              "type": null,
                              "description": null,
                              "name": "Domain 1.1.1.2.1"
                            }
                          ],
                          "type": null,
                          "description": null,
                          "name": "Domain 1.1.1.2"
                        }
                      ],
                      "type": null,
                      "description": null,
                      "name": "Domain 1.1.1"
                    }
                  ],
                  "type": null,
                  "description": null,
                  "name": "Domain 1.1"
                }
              ],
              "type": null,
              "description": null,
              "name": "Domain 1"
            },
            {
              "children": [
                {
                  "children": [],
                  "type": null,
                  "description": null,
                  "name": "Domain 2.1"
                },
                {
                  "children": [],
                  "type": null,
                  "description": null,
                  "name": "Domain 2.2"
                }
              ],
              "type": null,
              "description": null,
              "name": "Domain 2"
            },
            {
              "children": [
                {
                  "children": [],
                  "type": null,
                  "description": null,
                  "name": "Domain 3.1"
                },
                {
                  "children": [
                    {
                      "children": [],
                      "type": null,
                      "description": null,
                      "name": "Domain 3.2.1"
                    },
                    {
                      "children": [],
                      "type": null,
                      "description": null,
                      "name": "Domain 3.2.2"
                    }
                  ],
                  "type": null,
                  "description": null,
                  "name": "Domain 3.2"
                },
                {
                  "children": [],
                  "type": null,
                  "description": null,
                  "name": "Domain 3.3"
                },
                {
                  "children": [],
                  "type": null,
                  "description": null,
                  "name": "Domain 3.4"
                },
                {
                  "children": [
                    {
                      "children": [
                        {
                          "children": [
                            {
                              "children": [],
                              "type": null,
                              "description": null,
                              "name": "Domain 3.5.1.1.1"
                            }
                          ],
                          "type": null,
                          "description": null,
                          "name": "Domain 3.5.1.1"
                        },
                        {
                          "children": [],
                          "type": null,
                          "description": null,
                          "name": "Domain 3.5.1.2"
                        }
                      ],
                      "type": null,
                      "description": null,
                      "name": "Domain 3.5.1"
                    }
                  ],
                  "type": null,
                  "description": null,
                  "name": "Domain 3.5"
                }
              ],
              "type": null,
              "description": null,
              "name": "Domain 3"
            }
          ]
         """
