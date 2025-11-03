# Attention Gem - Design Document

## Overview

The **attention** gem is a Ruby engine that provides hierarchical task and priority management through INI-based configuration files. It enables teams to track task completion status (Attributes) and urgency (Priorities) across different facets of a project.

## Core Concepts

### 1. Attributes.ini
- Contains task completion metrics with values 0-1
- 0 = Nothing has been done
- 1 = Task is complete
- Organized by facets (e.g., Operator, TechnicalDebt)
- Values can be decimal for partial completion

### 2. Priorities.ini
- Contains urgency metrics with values 0-1
- 0 = Don't care
- 1 = Needs immediate attention
- Organized by the same facets as Attributes
- Values determine relative importance

### 3. Hierarchical Application
- Files at higher directory levels apply to lower levels
- Child configurations inherit parent settings
- Child values can override parent values

### 4. Priority Calculation
- Calculated Priority = Attribute Value × Priority Value
- Lower product = higher urgency (incomplete + important)
- Results sorted by calculated priority

## Gem Structure

```
attention/
├── lib/
│   ├── attention.rb                    # Main module
│   ├── attention/
│   │   ├── engine.rb                   # Rails engine configuration
│   │   ├── reader.rb                   # Read INI files from repo
│   │   ├── calculator.rb               # Calculate priorities
│   │   ├── dumper.rb                   # Export to JSON
│   │   ├── applier.rb                  # Import from JSON
│   │   └── reporter.rb                 # Generate reports
│   └── tasks/
│       └── attention.rake              # Rake tasks
├── spec/                               # RSpec tests
├── features/                           # Cucumber tests
├── attention.gemspec
├── Gemfile
└── README.md
```

## Rake Tasks

### attention:read_repo
Reads all Attributes.ini and Priorities.ini files in the repository with hierarchical inheritance.

### attention:dump:repo
Creates `attention_dump.json` containing all Attributes and Priorities data.

### attention:apply:repo
Writes Attributes.ini and Priorities.ini files from `attention_dump.json`.

### attention:report:priority_list
Generates a sorted report of all items by calculated priority (attribute × priority).

## Data Model

### INI File Format
```ini
[FacetName]
attribute_key=0.5
another_key=0.8
```

### JSON Dump Format
```json
{
  "path/to/directory": {
    "attributes": {
      "Operator": {
        "event_processing_works": 0
      },
      "TechnicalDebt": {
        "code_coverage": 0.3
      }
    },
    "priorities": {
      "Operator": {
        "event_processing_works": 1
      },
      "TechnicalDebt": {
        "code_coverage": 0.5
      }
    }
  }
}
```

### Priority Report Format
```
| Facet          | Attribute                  | Value | Priority | Score | Path              |
|----------------|----------------------------|-------|----------|-------|-------------------|
| Operator       | event_processing_works     | 0.0   | 1.0      | 0.0   | services/events   |
| TechnicalDebt  | code_coverage              | 0.3   | 0.5      | 0.15  | lib/core          |
```

## Algorithm: Hierarchical Resolution

1. Start from repository root
2. Traverse directory tree depth-first
3. At each level:
   - Read Attributes.ini and Priorities.ini if present
   - Merge with parent configuration
   - Child values override parent values
4. Build complete configuration map

## Algorithm: Priority Calculation

1. Collect all attribute-priority pairs from resolved configuration
2. For each pair:
   - Calculate score = attribute_value × priority_value
3. Sort by score (ascending = most urgent first)
4. Generate report

## Use Cases

### Production Outage Response
1. Create/update Attributes.ini in affected module
2. Set attribute to 0 (not fixed)
3. Create/update Priorities.ini
4. Set priority to 1 (critical)
5. Run `rake attention:report:priority_list`
6. Top item shows what needs immediate attention

### Technical Debt Management
1. Set attributes for code quality metrics
2. Set priorities based on business impact
3. Generate report to guide refactoring efforts

### Sprint Planning
1. Review priority report
2. Focus on items with lowest scores (high priority, low completion)
3. Update attributes as work progresses
