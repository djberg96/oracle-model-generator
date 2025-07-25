# SQL Server Docker Testing Guide

## 🚀 Quick Test

To quickly test SQL Server support with Docker:

```bash
./test_sqlserver_simple.sh
```

This will automatically:
1. ✅ Pull and start SQL Server 2022 Express
2. ✅ Create test database with sample tables
3. ✅ Test model generation with various scenarios
4. ✅ Show generated Ruby code
5. ✅ Clean up containers when done

## 📋 What Gets Tested

### Model Generation
- **Users model** with RSpec tests
- **Posts model** with foreign key relationships
- **Auto-detection** of SQL Server when `-s` parameter is used

### Index Recommendations
- Foreign key indexes
- Unique constraint indexes
- Date query indexes
- Status/enum indexes
- Composite indexes
- Full-text search recommendations

### Test Framework Support
- **RSpec** test generation
- **Minitest** test generation
- **TestUnit** test generation

## 🔧 Manual Testing

If you prefer manual control:

```bash
# 1. Start SQL Server
docker run -d --name sqlserver_test \
  -e "ACCEPT_EULA=Y" \
  -e "SA_PASSWORD=YourStrong!Passw0rd" \
  -e "MSSQL_PID=Express" \
  -p 1433:1433 \
  mcr.microsoft.com/mssql/server:2022-latest

# 2. Wait for startup (60 seconds)
sleep 60

# 3. Create test database
docker exec sqlserver_test /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P YourStrong!Passw0rd \
  -Q "CREATE DATABASE test_db"

# 4. Test the generator
ruby bin/dmg -T sqlserver -s localhost -P 1433 -d test_db \
  -u sa -p 'YourStrong!Passw0rd' -t sys.tables -x rspec

# 5. Clean up
docker stop sqlserver_test && docker rm sqlserver_test
```

## 📊 Sample Database Schema

The test creates realistic tables:

- **users** - User accounts with various data types
- **posts** - Blog posts with foreign keys to users
- **categories** - Hierarchical categories
- **post_categories** - Many-to-many junction table
- **comments** - Comments linking posts and users

## 🎯 Expected Results

### Generated User Model Example
```ruby
# Generated by Database Model Generator v0.6.0
class User < ActiveRecord::Base
  set_table_name "users"
  set_primary_key :id

  # Table relationships
  has_many :posts, class_name: 'Post'
  has_many :comments, class_name: 'Comment'

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :recent, -> { where('created_at > ?', 30.days.ago) }

  # Validations
  validates :username, length: {maximum: 50}, presence: true
  validates :email, length: {maximum: 100}, presence: true
  validates :first_name, length: {maximum: 50}, presence: true
  # ... more validations
end
```

### Index Recommendations Example
```
Foreign Keys:
  add_index :posts, :user_id

Unique Constraints:
  add_index :users, :username, unique: true
  add_index :users, :email, unique: true

Date Queries:
  add_index :users, :created_at
  add_index :posts, :published_at

Composite:
  add_index :posts, [:user_id, :created_at]
```

## 🔍 Verification Steps

The test script verifies:

1. **Docker availability** and SQL Server startup
2. **Database connectivity** using tiny_tds gem
3. **Model generation** with proper ActiveRecord syntax
4. **Test file creation** with chosen framework
5. **Index recommendations** based on table analysis
6. **Auto-detection** when server parameter provided
7. **Foreign key mapping** to belongs_to/has_many relationships

## 🛠️ Prerequisites

- **Docker** installed and running
- **Ruby** 2.7+ with bundler
- **tiny_tds gem** (auto-installed by test script)

## 🚨 Troubleshooting

### SQL Server Startup Issues
- **Wait longer**: SQL Server can take 2-3 minutes to start
- **Check logs**: `docker logs sqlserver_test`
- **Port conflicts**: Ensure port 1433 is available

### Connection Issues
- **Password complexity**: Must meet SQL Server requirements
- **Firewall**: Check local firewall settings
- **Container status**: Verify container is running and healthy

### Gem Installation
```bash
# Ubuntu/Debian
sudo apt-get install build-essential freetds-dev
gem install tiny_tds

# macOS
brew install freetds
gem install tiny_tds
```

## 📁 File Structure

```
docker/
├── README.md                    # This documentation
├── sqlserver/
│   ├── Dockerfile              # SQL Server container
│   ├── init-db.sql             # Database setup script
│   └── setup-db.sh             # Automation script
└── test/
    ├── Dockerfile              # Test runner container
    └── run_tests.sh            # Test suite

docker-compose.sqlserver.yml    # Docker Compose config
test_sqlserver_simple.sh        # Simple test script ⭐
test_sqlserver_docker.sh        # Advanced test script
```

## 🎉 Success Indicators

When everything works correctly, you'll see:

```
✅ Docker is available
✅ SQL Server container started
✅ SQL Server is ready!
✅ Test database created with sample data
✅ tiny_tds gem is available
✅ User model generated successfully!
✅ Auto-detection successful!
✅ Direct connection successful! Found 2 users
✅ All tests completed successfully!
```

The generated Ruby models will demonstrate that your Database Model Generator now fully supports SQL Server alongside Oracle! 🎊
