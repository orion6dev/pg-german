#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Starting the SSH service and logging the output
echo "Starting SSH service..."
service ssh start
ssh_status=$?
if [ $ssh_status -ne 0 ]; then
    echo "Failed to start SSH service with status: $ssh_status"
    exit $ssh_status
else
    echo "SSH service started successfully."
fi

# Ensure correct permissions on the PostgreSQL data directory
echo "Setting permissions on PostgreSQL data directory..."
chown -R postgres:postgres /var/lib/postgresql/data
chmod 700 /var/lib/postgresql/data

# Execute the original PostgreSQL entrypoint script
echo "Starting PostgreSQL using the official entrypoint script..."
exec docker-entrypoint.sh "$@"
