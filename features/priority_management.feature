Feature: Priority Management
  As a development team
  I want to track task completion and priorities
  So that I can focus on the most important incomplete work

  Background:
    Given I have a project with attention gem installed

  Scenario: Creating attributes and priorities for a production issue
    Given a critical production outage in the events service
    When I create an Attributes.ini file with:
      """
      [Operator]
      event_processing_works=0.0
      """
    And I create a Priorities.ini file with:
      """
      [Operator]
      event_processing_works=1.0
      """
    And I generate a priority report
    Then the report should show "event_processing_works" as the highest urgency item

  Scenario: Hierarchical inheritance of attributes
    Given I have a root Attributes.ini with:
      """
      [TechnicalDebt]
      code_coverage=0.5
      """
    And I have a subdirectory "services/events"
    And I have a subdirectory Attributes.ini with:
      """
      [TechnicalDebt]
      code_coverage=0.2
      
      [Operator]
      event_processing_works=0.0
      """
    When I read the repository data
    Then the subdirectory should inherit root attributes
    And the subdirectory should override "code_coverage" with 0.2

  Scenario: Dumping and applying repository data
    Given I have multiple directories with INI files
    When I dump the repository to JSON
    Then a file "attention_dump.json" should be created
    When I delete all INI files
    And I apply the repository from JSON
    Then all INI files should be restored

  Scenario: Calculating urgency for sprint planning
    Given I have the following attributes:
      | Path            | Facet         | Attribute       | Value |
      | services/events | Operator      | uptime          | 0.9   |
      | services/events | TechnicalDebt | code_coverage   | 0.3   |
      | lib/core        | TechnicalDebt | code_coverage   | 0.8   |
    And I have the following priorities:
      | Path            | Facet         | Attribute       | Value |
      | services/events | Operator      | uptime          | 0.5   |
      | services/events | TechnicalDebt | code_coverage   | 0.9   |
      | lib/core        | TechnicalDebt | code_coverage   | 0.3   |
    When I calculate urgency
    Then "services/events TechnicalDebt code_coverage" should have the highest urgency
    And the urgency should be 0.63

  Scenario: Tracking progress on technical debt
    Given I have a technical debt item with 30% completion
    When I update the completion to 80%
    And I generate a priority report
    Then the urgency should decrease
    And the completion percentage should show 80%
