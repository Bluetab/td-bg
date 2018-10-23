Feature: Ping
  Check if the server is alive 

  Scenario: Send ping
    When you send me a ping
    Then I send you a pong
