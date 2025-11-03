Feature: File-Level Tracking with Git Integration
  As a development team
  I want to automatically track files with Git object IDs
  So that I can monitor file changes and review status

  Background:
    Given I have a project with attention gem installed

  Scenario: Scanning directory and creating file facets
    Given I have Ruby files in my project directory
    When I run the file scanner
    Then file facets should be created for each Ruby file
    And each file facet should have a git_object_id attribute
    And each file facet should have a review_status attribute

  Scenario: Detecting file changes via Git object ID
    Given I have tracked files with git object IDs
    When I modify a tracked file
    And I update the git object IDs
    Then the git_object_id should change for the modified file
    And other files should retain their original git_object_id

  Scenario: Cleaning up deleted file facets
    Given I have file facets for existing files
    When I delete a tracked file
    And I run the cleanup task
    Then the facet for the deleted file should be removed
    And facets for existing files should remain

  Scenario: File facets and manual facets coexist
    Given I have manual facets for TechnicalDebt
    And I have file facets for tracked files
    When I generate a priority report
    Then the report should include both manual and file facets
    And they should be sorted by urgency

  Scenario: Hierarchical inheritance with file facets
    Given I have file facets at the root level
    And I have file facets in a subdirectory
    When I read the repository data
    Then subdirectory file facets should not inherit from root file facets
    But subdirectory should inherit manual facets from root

  Scenario: Git repository detection
    Given I am in a Git repository
    When I check Git integration status
    Then it should detect the Git repository
    And git object IDs should be calculated using Git

  Scenario: Non-Git repository fallback
    Given I am not in a Git repository
    When I scan files for tracking
    Then git object IDs should be calculated manually
    And file tracking should still work correctly

  Scenario: File tracking statistics
    Given I have a mix of file and manual facets
    When I request tracking statistics
    Then I should see the count of file facets
    And I should see the count of manual facets
    And I should see the total facet count
