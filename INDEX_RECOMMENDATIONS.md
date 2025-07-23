# Index Recommendations Feature

The Oracle Model Generator now includes intelligent index recommendations to help optimize your database performance. This feature analyzes your Oracle database schema and suggests indexes based on common query patterns and best practices.

## How It Works

The generator analyzes your table structure and identifies:

### 1. **Foreign Key Indexes**
- **Purpose**: Speed up JOIN operations and foreign key constraint validation
- **Detection**: Automatically finds all foreign key relationships
- **Impact**: 10-100x faster JOIN performance

```sql
add_index :employees, :department_id  # Foreign key index
add_index :orders, :customer_id       # Foreign key index
```

### 2. **Unique Constraint Indexes**
- **Purpose**: Enforce uniqueness and speed up unique lookups
- **Detection**: Identifies email, username, code, slug, uuid, and token columns
- **Impact**: Instant uniqueness validation, faster unique lookups

```sql
add_index :users, :email, unique: true     # Unique email constraint
add_index :products, :code, unique: true   # Unique product code
```

### 3. **Date/Timestamp Indexes**
- **Purpose**: Optimize date range queries and temporal filtering
- **Detection**: Finds date, timestamp, and date-named columns
- **Impact**: 5-50x faster date range queries

```sql
add_index :orders, :created_at        # Date range queries
add_index :events, :start_date        # Event scheduling queries
```

### 4. **Status/Enum Indexes**
- **Purpose**: Speed up status-based filtering
- **Detection**: Identifies status, state, type, role, priority, level columns
- **Impact**: Fast filtering by status categories

```sql
add_index :orders, :status           # Order status filtering
add_index :users, :role              # User role filtering
```

### 5. **Composite Indexes**
- **Purpose**: Optimize multi-column WHERE clauses
- **Detection**: Combines foreign keys with dates, status with dates
- **Impact**: Optimal performance for common query patterns

```sql
add_index :orders, [:customer_id, :created_at]  # Customer order history
add_index :tasks, [:status, :due_date]          # Status + deadline queries
```

### 6. **Full-Text Search Indexes**
- **Purpose**: Enable fast text search capabilities
- **Detection**: Large text columns (name, title, description, content)
- **Impact**: Sophisticated text search with Oracle Text

```sql
CREATE INDEX idx_products_description_text
ON PRODUCTS (DESCRIPTION) INDEXTYPE IS CTXSYS.CONTEXT;
```

## Usage

### Command Line Interface

Generate a model with index recommendations included:
```bash
./bin/omg -t employees -u hr -p hr -s localhost:1521/XE
```

Show only index recommendations (no model generation):
```bash
./bin/omg -t employees -u hr -p hr -s localhost:1521/XE --indexes
```

### Programmatic API

```ruby
connection = OCI8.new(user, password, database)
omg = Oracle::Model::Generator.new(connection)
omg.generate('employees')

# Get structured recommendations
recommendations = omg.index_recommendations

# Access specific recommendation types
recommendations[:foreign_keys]      # Foreign key indexes
recommendations[:unique_constraints] # Unique indexes
recommendations[:date_queries]       # Date-based indexes
recommendations[:status_enum]        # Status/enum indexes
recommendations[:composite]          # Multi-column indexes
recommendations[:full_text]          # Text search indexes
```

## Generated Output

When generating models, index recommendations appear as comments:

```ruby
class Employee < ActiveRecord::Base
  # Recommended Indexes (add these to your database migration):
  # add_index :employees, :department_id  # Foreign key index
  # add_index :employees, :email, unique: true  # Unique constraint
  # add_index :employees, :hire_date  # Date queries
  # add_index :employees, [:department_id, :hire_date]  # Composite index

  # ... rest of model ...
end
```

## Performance Benefits

| Index Type | Performance Gain | Use Case |
|------------|------------------|----------|
| Foreign Key | 10-100x | JOIN operations, referential integrity |
| Unique | Instant validation | Email lookups, username checks |
| Date | 5-50x | Date ranges, temporal queries |
| Status/Enum | 3-20x | Status filtering, category searches |
| Composite | 2-100x | Multi-column WHERE clauses |
| Full-Text | Search capable | Text search, content queries |

## Migration Generation

The `--indexes` option generates ready-to-use Rails migrations:

```ruby
class AddIndexesToEmployees < ActiveRecord::Migration[7.0]
  def change
    # Foreign key indexes
    add_index :employees, :department_id
    add_index :employees, :manager_id

    # Unique constraints
    add_index :employees, :email, unique: true

    # Date optimization
    add_index :employees, :hire_date

    # Composite indexes
    add_index :employees, [:department_id, :hire_date]
  end
end
```

## Best Practices

1. **Start with Foreign Keys**: Always index foreign key columns first
2. **Unique Constraints**: Add unique indexes for business keys (email, username)
3. **Query-Driven**: Add indexes based on your actual query patterns
4. **Monitor Usage**: Use Oracle's index usage statistics to validate effectiveness
5. **Composite Strategy**: Order composite index columns by selectivity (most selective first)

## Oracle-Specific Features

### Oracle Text Indexes
For full-text search capabilities:
```sql
CREATE INDEX idx_table_column_text
ON TABLE_NAME (COLUMN_NAME) INDEXTYPE IS CTXSYS.CONTEXT;
```

### Function-Based Indexes
For case-insensitive searches:
```sql
CREATE INDEX idx_users_email_upper
ON USERS (UPPER(EMAIL));
```

### Partitioned Indexes
For very large tables with date partitioning:
```sql
CREATE INDEX idx_orders_date_local
ON ORDERS (ORDER_DATE) LOCAL;
```

## Integration with ActiveRecord

The recommended indexes work seamlessly with ActiveRecord queries:

```ruby
# Optimized by foreign key index
Employee.joins(:department).where(department: dept)

# Optimized by unique index
User.find_by(email: 'user@example.com')

# Optimized by date index
Order.where('created_at > ?', 1.week.ago)

# Optimized by composite index
Task.where(status: 'pending', due_date: Date.tomorrow)

# Optimized by Oracle Text index
Product.where("CONTAINS(description, ?) > 0", search_term)
```

This intelligent indexing feature helps ensure your Oracle-backed Rails applications achieve optimal performance from day one.
