'''
# Attention Gem: Hierarchical Task & Priority Management

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Attention** is a Ruby engine gem that provides a powerful and flexible system for managing task completion and priorities across your projects. It uses a hierarchical structure of simple INI files to track what needs to be done and how urgently it needs attention, enabling teams to focus on what matters most.

This project provides a complete, working implementation of the `attention` gem, including the core engine, Rake tasks for easy integration, a comprehensive test suite, and a detailed example project.

## New in This Version: File-Level Tracking with Git Integration

This version introduces a major enhancement: **automatic file-level tracking**. The gem can now automatically create facets for each file in your project, complete with Git object IDs for precise change tracking. This enables fine-grained monitoring of code reviews, refactoring efforts, and more, right down to the individual file level.

### Key Features of File Tracking:

-   **Automatic Facet Generation**: Creates a unique facet for each trackable file (e.g., `.rb`, `.py`, `.js`).
-   **Git Object ID Tracking**: Each file facet includes a `git_object_id` to detect changes.
-   **Custom File Attributes**: Add your own attributes to file facets, such as `review_status` or `refactoring_needed`.
-   **Seamless Integration**: File facets coexist with manual facets and participate in the same hierarchical and priority calculation logic.

## Core Concepts

The gem's logic is built on two types of files:

-   **`Attributes.ini`**: Tracks the completion status of a task. Values range from **0.0** (not started) to **1.0** (complete).
-   **`Priorities.ini`**: Defines the importance of a task. Values range from **0.0** (no priority) to **1.0** (immediate attention required).

These files are organized into **facets**, which are simply sections within the INI file that group related items. Facets can be manual (e.g., `[Operator]`) or automatically generated for files (e.g., `[File:event_processor.rb]`)

### Hierarchical Power

The true power of `attention` lies in its hierarchical configuration. INI files in a parent directory are automatically inherited by its subdirectories. This allows you to set global priorities and attributes at the root of your project, which can then be refined or overridden at more specific levels.

### Urgency Calculation

The gem calculates the **urgency** of each item to help you prioritize work. The formula is:

> **Urgency = (1 - Attribute Value) * Priority Value**

This calculation highlights tasks that are both **important** (high priority) and **incomplete** (low attribute value).

## Architecture Overview

The gem is composed of several key components that work together to read, calculate, and report on your project's priorities. The new file tracking modules integrate seamlessly into the existing architecture.

![Attention Gem Architecture with File Tracking](https://github.com/Manus-AI/assets/raw/main/attention_architecture_file_tracking.png)

*A UML diagram illustrating the enhanced architecture of the attention gem with file tracking capabilities.*

## Getting Started

### Installation

Add this line to your application's Gemfile:

```ruby
gem 'attention', git: 'https://github.com/your-repo/attention.git'
```

And then execute:

```bash
$ bundle install
```

### Usage

1.  **Initialize your project as a Git repository** (if it isn't already).

    ```bash
    $ git init
    ```

2.  **Scan for files**: Run the new Rake task to automatically generate file facets.

    ```bash
    $ rake attention:files:scan
    ```

3.  **Customize priorities**: Add priorities for your new file facets in the corresponding `Priorities.ini` files.

    **`services/events/Priorities.ini`**
    ```ini
    [File:event_processor.rb]
    review_status=0.9
    ```

4.  **Generate a report**: Use the standard Rake task to see a sorted list of your project's priorities, now including file-level items.

    ```bash
    $ rake attention:report:priority_list
    ```

## Rake Tasks

The gem includes the following Rake tasks to manage your attention data:

### Core Tasks

| Task                            | Description                                                              |
| ------------------------------- | ------------------------------------------------------------------------ |
| `attention:read_repo`           | Reads and displays all `Attributes.ini` and `Priorities.ini` files.      |
| `attention:dump:repo`           | Exports all attention data into a single `attention_dump.json` file.     |
| `attention:apply:repo`          | Imports data from `attention_dump.json` and recreates the INI files.     |
| `attention:report:priority_list`| Generates a sorted report of all items by calculated urgency.            |
| `attention:report:detailed`     | Provides a summary and detailed breakdown of project metrics.            |

### File Tracking Tasks

| Task                            | Description                                                              |
| ------------------------------- | ------------------------------------------------------------------------ |
| `attention:files:scan`          | Scans directories and creates/updates file facets with Git object IDs.   |
| `attention:files:update_git_ids`| Updates the `git_object_id` for all tracked files that have changed.     |
| `attention:files:cleanup`       | Removes facets for files that have been deleted from the project.        |
| `attention:files:stats`         | Displays statistics on the number of manual vs. file facets.             |
| `attention:files:list`          | Lists all files in a directory that are eligible for tracking.           |

## Example Project

A complete example project is included to demonstrate a real-world use case with a multi-level hierarchical structure and the new file tracking features. It showcases how to track priorities for different services, libraries, and individual source code files.

### Example Report with File Facets

Here is a sample priority report generated from the enhanced example project, showing both manual and file-based facets:

```
Top 10 items by urgency (including file facets):

 1. [MANUAL] Operator                  event_processing_works
    Urgency: 1.0000 | Complete:   0.0% | Priority: 1.00 | Path: services/events

 2. [MANUAL] TechnicalDebt             code_coverage
    Urgency: 0.7200 | Complete:  20.0% | Priority: 0.90 | Path: services/events

 3. [MANUAL] TechnicalDebt             refactoring_needed
    Urgency: 0.5600 | Complete:  30.0% | Priority: 0.80 | Path: lib/core

 4. [FILE]   File:event_processor.rb   review_status
    Urgency: 0.0000 | Complete:   0.0% | Priority: 0.00 | Path: services/events
...
```

## Testing

The gem includes a comprehensive test suite using **RSpec** for unit tests and **Cucumber** for behavior-driven development (BDD). To run the tests, execute:

```bash
$ bundle exec rspec
$ bundle exec cucumber
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
'''
