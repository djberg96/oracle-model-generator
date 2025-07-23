# Docker Testing Environment for Oracle Model Generator

This directory contains a complete Docker setup for testing the oracle-model-generator Ruby library with Oracle database connectivity.

## Files Created

### Docker Configuration
- `Dockerfile` - Production-ready Docker image with Oracle connectivity
- `docker-compose.yml` - Complete testing environment with Oracle XE database
- `.dockerignore` - Optimizes Docker build context

### Testing Files
- `test/test_oracle_model_generator_docker.rb` - Docker-optimized test suite
- `DOCKER.md` - Detailed documentation and troubleshooting guide

## Quick Start

### Option 1: Full Testing Environment (with Oracle Database)

1. **Start the complete environment:**
   ```bash
   docker-compose up -d
   ```

2. **Wait for Oracle database to be ready:**
   ```bash
   docker-compose logs -f oracle-db
   # Wait for "DATABASE IS READY TO USE!" message
   ```

3. **Run tests:**
   ```bash
   docker-compose exec app ruby test/test_oracle_model_generator_docker.rb
   ```

4. **Interactive shell for development:**
   ```bash
   docker-compose exec app bash
   ```

### Option 2: Build and Test Application Only

1. **Build the image:**
   ```bash
   docker build -t oracle-model-generator .
   ```

2. **Run with external database:**
   ```bash
   docker run -e ORACLE_HOST=your-db-host \
              -e ORACLE_PORT=1521 \
              -e ORACLE_SID=your-sid \
              -e ORACLE_USER=your-user \
              -e ORACLE_PASSWORD=your-password \
              oracle-model-generator
   ```

## Environment Variables

The Docker environment supports these variables for database connection:

- `ORACLE_HOST` - Database hostname (default: oracle-db)
- `ORACLE_PORT` - Database port (default: 1521)
- `ORACLE_SID` - Database SID (default: XE)
- `ORACLE_USER` - Database username (default: hr)
- `ORACLE_PASSWORD` - Database password (default: oracle)

## What's Included

### Oracle Instant Client 19.13
- Full Oracle connectivity libraries
- Properly configured environment variables
- Native compilation support for ruby-oci8

### Ruby Environment
- Ruby 3.1 with bundler
- All project dependencies installed
- Optimized for Oracle development

### Test Database (via docker-compose)
- Oracle Express Edition 21c
- Pre-configured HR sample schema
- Ready-to-use test data

## Development Workflow

1. **Make code changes** in your local workspace
2. **Rebuild the image:** `docker-compose build app`
3. **Run tests:** `docker-compose exec app ruby test/test_oracle_model_generator_docker.rb`
4. **Debug interactively:** `docker-compose exec app bash`

## Troubleshooting

### Common Issues

1. **ruby-oci8 compilation errors:**
   - Ensure Oracle Instant Client is properly installed
   - Check environment variables are set correctly
   - Verify build-essential package is installed

2. **Database connection failures:**
   - Wait for Oracle container to fully initialize
   - Check network connectivity between containers
   - Verify database credentials

3. **Permission issues:**
   - Ensure Docker has necessary permissions
   - Check file ownership in mounted volumes

### Debugging Commands

```bash
# Check Oracle client installation
docker-compose exec app ls -la /opt/oracle/instantclient_19_13/

# Test database connectivity
docker-compose exec app sqlplus hr/oracle@oracle-db:1521/XE

# Check environment variables
docker-compose exec app env | grep ORACLE

# View bundler gem installation
docker-compose exec app bundle list
```

## Performance Notes

- Initial build takes 10-15 minutes (Oracle client compilation)
- Subsequent builds use Docker layer caching
- Oracle database initialization takes 2-3 minutes
- Consider using volumes for persistent development

## Security Considerations

- Default passwords are for development only
- Use Docker secrets for production deployments
- Limit network exposure in production environments
- Regular security updates for base images

For detailed information, see `DOCKER.md`.
