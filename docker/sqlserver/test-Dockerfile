# Test container for Database Model Generator with SQL Server
FROM ruby:3.1-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    build-essential \
    unixodbc-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Microsoft ODBC Driver for SQL Server
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql17 \
    && rm -rf /var/lib/apt/lists/*

# Set work directory
WORKDIR /app

# Copy Gemfile and install dependencies
COPY Gemfile* ./
RUN bundle install

# Copy application code
COPY . .

# Install tiny_tds gem for SQL Server connectivity
RUN gem install tiny_tds

# Make test script executable
RUN chmod +x docker/test/run_tests.sh

# Default command
CMD ["./docker/test/run_tests.sh"]
