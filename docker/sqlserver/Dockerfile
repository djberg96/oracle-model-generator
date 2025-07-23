# SQL Server Docker setup for testing Database Model Generator
FROM mcr.microsoft.com/mssql/server:2022-latest

# Set environment variables
ENV ACCEPT_EULA=Y
ENV SA_PASSWORD=YourStrong!Passw0rd
ENV MSSQL_PID=Express

# Expose SQL Server port
EXPOSE 1433

# Switch to root to create directories and copy files
USER root

# Create directory for initialization scripts
RUN mkdir -p /opt/mssql-tools/scripts

# Copy initialization scripts
COPY docker/sqlserver/init-db.sql /opt/mssql-tools/scripts/
COPY docker/sqlserver/setup-db.sh /opt/mssql-tools/scripts/

# Make setup script executable
RUN chmod +x /opt/mssql-tools/scripts/setup-db.sh

# Switch back to mssql user
USER mssql

# Run SQL Server and setup script
CMD /opt/mssql-tools/scripts/setup-db.sh & /opt/mssql/bin/sqlservr
