Feature: Business Concepts administration
  A business concept has a workflow with following status depending on the executed action:
     | initial status   | action            | new status       |
     |                  | create            | draft            |
     | draft            | modification      | draft            |
     | draft            | send for approval | pending approval |
     | draft            | delete            | deleted          |
     | pending approval | publish           | published        |
     | pending approval | reject            | rejected         |
     | rejected         | delete            | deleted          |
     | rejected         | modification      | draft            |
     | rejected         | send for approval | pending approval |
     | published        | modification      | draft            |
     | published        | deprecate         | deprecated       |

  Users will be able to run actions depending on the role they have in the
  Business Concept's Data Domain:
    |          | create  | modification | send for approval | delete | publish | reject | deprecate | see draft | see published |
    | admin    |    X    |      X       |        X          |   X    |    X    |   X    |     X     |     X     |     X         |
    | publish  |    X    |      X       |        X          |   X    |    X    |   X    |     X     |     X     |     X         |
    | create   |    X    |      X       |        X          |   X    |         |        |           |     X     |     X         |
    | watch    |         |              |                   |        |         |        |           |           |     X         |

  In this feature we cover the creation as draft, modification, publishing and deletion
  of business concepts.
  Concepts are used by the business to declare the common language that is going
  to be used by the whole organization, the rules to be followed by the data and
  the relations between concepts.
  Relation between concept types is defined at a concept type level.
  Concepts must be unique by domain and name.
