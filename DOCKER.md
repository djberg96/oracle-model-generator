# Docker Testing Environment for Oracle Model Generator

This directory contains Docker configuration files to create a complete testing environment for the oracle-model-generator library.

## Quick Start

### Using Docker Compose (Recommended)

The easiest way to test the library is using Docker Compose, which will start both an Oracle database and the testing environment:

```bash
# Build and start the services
docker-compose up --build

# This will:
# 1. Download and start Oracle Express Edition
# 2. Build the oracle-model-generator testing image
# 3. Set up the HR sample schema
# 4. Start an interactive shell in the testing container
```

### Manual Docker Build

If you prefer to build just the testing image:

```bash
# Build the Docker image
docker build -t oracle-model-generator-test .

# Run with a separate Oracle database
docker run -it --rm \
  -e ORACLE_HOST=your-oracle-host \
  -e ORACLE_PORT=1521 \
  -e ORACLE_USER=hr \
  -e ORACLE_PASSWORD=hr \
  oracle-model-generator-test
```

## Running Tests

Once inside the container, you can run various commands:

```bash
# Run the Docker environment test to verify everything is working
bundle exec ruby test/docker_environment_test.rb

# Run the test suite
bundle exec ruby test/test_oracle_model_generator.rb

# Run the Docker-adapted test suite (uses environment variables)
bundle exec ruby test/test_oracle_model_generator_docker.rb

# Test the command-line tool
bundle exec ruby -Ilib bin/omg --help

# Interactive Ruby with the library loaded
irb -I lib -r oracle/model/generator
```

## Environment Variables

The Docker environment supports these environment variables:

- `ORACLE_HOST`: Oracle database hostname (default: localhost)
- `ORACLE_PORT`: Oracle database port (default: 1521)
- `ORACLE_SID`: Oracle database SID (default: XE)
- `ORACLE_USER`: Database username (default: hr)
- `ORACLE_PASSWORD`: Database password (default: hr)

## What's Included

The Docker image includes:

- Ruby 3.1 with all required gems
- Oracle Instant Client 21.13
- All dependencies for ruby-oci8
- The oracle-model-generator library
- Test framework (test-unit)

## Oracle Database Requirements

The tests expect an Oracle database with the HR sample schema. The Docker Compose setup automatically creates this using the `gvenzl/oracle-xe` image.

If you're using your own Oracle database, make sure:

1. The HR schema is installed and accessible
2. The user has appropriate permissions
3. The following tables/views exist:
   - `employees`
   - `emp_details_view`

## Troubleshooting

### macOS Docker Issues

On macOS, you might encounter shared memory issues with the Oracle XE container:

```
ORA-27104: system-defined limits for shared memory was misconfigured
```

**Workaround**: Test the application container directly:

```bash
# Build and test just the application
docker build -t oracle-model-generator-test .

# Run the environment verification test
docker run --rm oracle-model-generator-test bundle exec ruby test/docker_environment_test.rb

# Interactive testing without database
docker run -it --rm oracle-model-generator-test bash
```

### Connection Issues

If you get Oracle connection errors:

1. Check that the Oracle database is running: `docker-compose ps`
2. Wait for the database to be fully initialized (can take 2-3 minutes)
3. Verify connection parameters match your setup

### Build Issues

If the Docker build fails:

1. Make sure you have internet access (downloads Oracle Instant Client)
2. Try rebuilding: `docker-compose build --no-cache`

### Test Failures

If tests fail but connection works:

1. Verify the HR schema is properly installed
2. Check that sample data is present
3. Ensure the user has necessary permissions

## Development

To develop/debug the library using Docker:

```bash
# Start the container with a bash shell
docker-compose run oracle-model-generator bash

# Or mount the local directory for live editing
docker run -it --rm -v $(pwd):/app oracle-model-generator-test bash
```

## Cleaning Up

To remove all Docker resources:

```bash
# Stop and remove containers
docker-compose down

# Also remove volumes (this will delete the Oracle database data)
docker-compose down -v

# Remove the built images
docker rmi oracle-model-generator-test
docker rmi gvenzl/oracle-xe:21-slim
```
