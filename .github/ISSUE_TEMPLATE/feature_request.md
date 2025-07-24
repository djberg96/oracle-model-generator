---
name: Feature Request
about: Suggest a new feature for the model generator
title: '[FEATURE] '
labels: ['enhancement']
assignees: ''

---

## Feature Description
A clear and concise description of the feature you'd like to see added.

## Use Case
Describe the specific problem this feature would solve or the workflow it would improve.

## Database Support
**Target Database(s):** Oracle / SQL Server / Both
**Database Features:** (e.g., specific constraint types, column types, etc.)

## Proposed Implementation
If you have ideas about how this could be implemented, please describe them here.

## Example
### Current Behavior
```ruby
# What the generator currently produces
class Example < ActiveRecord::Base
  # ...
end
```

### Desired Behavior
```ruby
# What you'd like it to produce instead
class Example < ActiveRecord::Base
  # new feature here
  has_many :related_models, dependent: :destroy
end
```

## Related Tables/Schema
If this feature relates to specific database schema patterns, please provide examples:
```sql
-- Example table structure that would benefit from this feature
CREATE TABLE examples (
  id NUMBER PRIMARY KEY,
  -- relevant columns
);
```

## Additional Context
- Would this be an optional feature or always enabled?
- Are there any performance considerations?
- Should this work with both Oracle and SQL Server?
- Any compatibility concerns with existing Rails versions?
