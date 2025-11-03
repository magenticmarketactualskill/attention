# File-Level Tracking Design

## Overview

This enhancement adds automatic file-level facet generation to the attention gem. Each file in a directory will have its own facet in `Attributes.ini`, and each facet will include a `git_object_id` attribute to track changes via Git.

## Requirements

1. **Automatic Facet Generation**: For each file in a directory, create a facet named after the file.
2. **Git Object ID Tracking**: Each file facet must include a `git_object_id` attribute containing the Git blob object ID.
3. **File Attributes**: Additional attributes can be added to track file-specific metrics (e.g., review_status, test_coverage).
4. **Backward Compatibility**: Existing manual facets should continue to work alongside auto-generated file facets.

## File Facet Naming Convention

File facets will be named using the following pattern:

```
[File:relative/path/to/file.rb]
```

This distinguishes file facets from manual facets and allows for easy identification.

## Attributes.ini Structure

### Example with File Facets

```ini
# Manual facets (existing functionality)
[Operator]
event_processing_works=0.0

[TechnicalDebt]
code_coverage=0.3

# Auto-generated file facets
[File:event_processor.rb]
git_object_id=a3f5b2c1d4e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0
review_status=0.0
refactoring_needed=0.5

[File:message_handler.rb]
git_object_id=b4c6d3e2f5a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1
review_status=1.0
refactoring_needed=0.0
```

## New Components

### 1. FileScanner

**Purpose**: Scan directories and identify all trackable files.

**Responsibilities**:
- Traverse directory structure
- Identify files to track (exclude .ini files, hidden files, etc.)
- Return list of files with relative paths

### 2. GitIntegration

**Purpose**: Interface with Git to retrieve object IDs.

**Responsibilities**:
- Get Git blob object ID for a given file
- Verify Git repository status
- Handle non-Git repositories gracefully

### 3. FileTracker

**Purpose**: Generate and update file facets in Attributes.ini.

**Responsibilities**:
- Create file facets for new files
- Update git_object_id when files change
- Remove facets for deleted files
- Preserve manual attributes in file facets

## Rake Tasks

### New Tasks

```bash
# Scan directory and generate file facets
rake attention:files:scan

# Update git_object_id for all tracked files
rake attention:files:update_git_ids

# Remove facets for deleted files
rake attention:files:cleanup
```

## Git Object ID Calculation

The Git object ID (blob hash) is calculated using Git's internal algorithm:

```ruby
# Git blob object ID formula:
# SHA-1("blob " + filesize + "\0" + contents)
```

We'll use Git command-line tools for reliability:

```bash
git hash-object path/to/file.rb
```

## Workflow

### Initial Setup

1. Developer runs `rake attention:files:scan` in a directory
2. FileScanner identifies all files
3. GitIntegration retrieves object IDs
4. FileTracker creates/updates Attributes.ini with file facets

### Ongoing Maintenance

1. After file changes, run `rake attention:files:update_git_ids`
2. Git object IDs are updated for modified files
3. Developers can add custom attributes to file facets manually
4. Run `rake attention:files:cleanup` to remove deleted file facets

## Integration with Existing Components

### Reader

- Must parse file facets alongside manual facets
- File facets participate in hierarchical inheritance
- git_object_id is treated as a regular attribute

### Calculator

- File facets are included in urgency calculations
- git_object_id itself is not used in calculations (priority would be 0)
- Other file attributes (review_status, etc.) are calculated normally

### Reporter

- File facets appear in reports
- Can filter reports to show only file facets or only manual facets
- Can group by file type or directory

## Example Use Cases

### Use Case 1: Code Review Tracking

```ini
[File:user_controller.rb]
git_object_id=abc123...
review_status=0.0
security_review=0.0
```

Priority: High priority for unreviewed files

### Use Case 2: Refactoring Tracking

```ini
[File:legacy_parser.rb]
git_object_id=def456...
refactoring_needed=0.2
test_coverage=0.4
```

Priority: Track refactoring progress per file

### Use Case 3: Change Detection

When `git_object_id` changes, it indicates the file has been modified. This can trigger:
- Automatic re-review requirements
- Test coverage re-validation
- Documentation update checks

## Configuration

Add configuration options to control file tracking:

```ruby
Attention.configure do |config|
  config.track_files = true
  config.file_extensions = ['.rb', '.js', '.py']
  config.exclude_patterns = ['*_test.rb', 'spec/**/*']
  config.auto_update_git_ids = true
end
```

## Data Model Changes

### Attributes.ini

- Supports both manual facets and file facets
- File facets must include `git_object_id`
- File facets are prefixed with `File:`

### JSON Dump Format

```json
{
  "path/to/directory": {
    "attributes": {
      "Operator": { ... },
      "File:example.rb": {
        "git_object_id": "abc123...",
        "review_status": 0.0
      }
    }
  }
}
```

## Benefits

1. **Automatic Tracking**: No manual facet creation needed for files
2. **Change Detection**: Git object IDs provide reliable change tracking
3. **Fine-Grained Metrics**: Track attributes per file, not just per directory
4. **Audit Trail**: Git object IDs provide historical reference
5. **Integration**: Works seamlessly with existing attention gem features
