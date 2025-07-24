---
name: Database Compatibility Issue
about: Report an issue with Oracle or SQL Server database compatibility
title: '[DB] '
labels: ['bug', 'database']
assignees: ''

---

## Database Information
**Database Type:** Oracle / SQL Server
**Database Version:** (e.g., Oracle 21c, SQL Server 2022)
**Ruby Version:** (e.g., 3.3.0)
**Gem Version:** (e.g., 0.6.0)

## Environment
**Operating System:** (e.g., Ubuntu 22.04, macOS 14, Windows 11)
**Connection Method:** (e.g., ruby-oci8, tiny_tds)

## Table Schema
Please provide the table schema that's causing issues:
```sql
-- Paste your table DDL here
CREATE TABLE example_table (
  id NUMBER PRIMARY KEY,
  -- ...
);
```

## Expected Behavior
What did you expect the model generator to produce?

## Actual Behavior
What actually happened? Please include the generated model code if relevant.

## Command Used
```bash
# Paste the exact dmg command you used
dmg -T oracle -s localhost -d mydb -u user -p pass -t mytable
```

## Error Output
```
Paste any error messages here
```

## Additional Context
- Are you using polymorphic associations?
- Are there CHECK constraints for enums?
- Any special database features (partitioning, etc.)?
- Docker environment or native installation?

## Reproducible Test Case
If possible, provide a minimal SQL script to recreate the issue:
```sql
-- Minimal table creation script
-- that reproduces the problem
```
