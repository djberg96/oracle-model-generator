# SQL Server Docker setup for testing Database Model Generator
FROM mcr.microsoft.com/mssql/server:2022-latest

# Set environment variables
ENV ACCEPT_EULA=Y
ENV SA_PASSWORD=YourStrong!Passw0rd
ENV MSSQL_PID=Express

# Expose SQL Server port
EXPOSE 1433

# Create directory for initialization scripts
RUN mkdir -p /usr/src/app

# Copy initialization scripts
COPY init-db.sql /usr/src/app/
COPY setup-db.sh /usr/src/app/

# Make setup script executable
RUN chmod +x /usr/src/app/setup-db.sh

# Run SQL Server and setup script
CMD /usr/src/app/setup-db.sh & /opt/mssql/bin/sqlservr
