# Dockerfile for testing oracle-model-generator library
FROM ruby:3.1-bullseye

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    libaio1 \
    libaio-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Download and install Oracle Instant Client
WORKDIR /opt/oracle
RUN wget https://download.oracle.com/otn_software/linux/instantclient/1913000/instantclient-basic-linux.x64-19.13.0.0.0dbru.zip && \
    wget https://download.oracle.com/otn_software/linux/instantclient/1913000/instantclient-sdk-linux.x64-19.13.0.0.0dbru.zip && \
    unzip instantclient-basic-linux.x64-19.13.0.0.0dbru.zip && \
    unzip instantclient-sdk-linux.x64-19.13.0.0.0dbru.zip && \
    rm -f *.zip

# Set Oracle environment variables
ENV ORACLE_HOME=/opt/oracle/instantclient_19_13
ENV LD_LIBRARY_PATH=$ORACLE_HOME
ENV PATH=$ORACLE_HOME:$PATH

# Create symbolic links for OCI8 compilation
RUN cd $ORACLE_HOME && \
    ln -sf libclntsh.so.19.1 libclntsh.so && \
    ln -sf libocci.so.19.1 libocci.so

# Set working directory for the application
WORKDIR /app

# Copy gemspec and Gemfile first for better Docker layer caching
COPY oracle-model-generator.gemspec Gemfile ./

# Install Ruby dependencies
RUN bundle config set --local deployment false && \
    bundle install --verbose

# Copy the rest of the application
COPY . .

# Create a script to run tests with Oracle connection
RUN echo '#!/bin/bash\n\
echo "Starting Oracle Model Generator test environment..."\n\
echo ""\n\
echo "This Docker container includes:"\n\
echo "- Ruby $(ruby --version)"\n\
echo "- Oracle Instant Client 19.13"\n\
echo "- All required gems for oracle-model-generator"\n\
echo ""\n\
echo "To run tests, you need to:"\n\
echo "1. Have an Oracle database running (Oracle XE recommended)"\n\
echo "2. Ensure the '\''hr'\'' schema is available with sample data"\n\
echo "3. Update connection parameters in test file if needed"\n\
echo ""\n\
echo "Available commands:"\n\
echo "  bundle exec ruby test/test_oracle_model_generator.rb  # Run tests"\n\
echo "  bundle exec ruby -Ilib bin/omg --help                # Run CLI tool"\n\
echo "  irb -I lib -r oracle/model/generator                 # Interactive Ruby"\n\
echo ""\n\
echo "Current Oracle environment:"\n\
echo "  ORACLE_HOME: $ORACLE_HOME"\n\
echo "  LD_LIBRARY_PATH: $LD_LIBRARY_PATH"\n\
echo ""\n\
\n\
# Check if arguments were passed to run specific commands\n\
if [ $# -eq 0 ]; then\n\
    echo "No command specified. Starting bash shell..."\n\
    exec /bin/bash\n\
else\n\
    exec "$@"\n\
fi' > /app/run_tests.sh

RUN chmod +x /app/run_tests.sh

# Expose any ports that might be needed (none for this library)
# EXPOSE 8080

# Set the default command
CMD ["/app/run_tests.sh"]

# Add some helpful labels
LABEL maintainer="Testing Environment for oracle-model-generator"
LABEL description="Docker image for testing the oracle-model-generator Ruby library with Oracle Instant Client"
LABEL version="1.0"
