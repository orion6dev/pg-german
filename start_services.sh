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

# Set correct permissions for SSH directory and files
echo "Setting permissions for SSH directory and files..."
chown -R postgres:postgres /var/lib/postgresql/.ssh
chmod 700 /var/lib/postgresql/.ssh
chmod 600 /var/lib/postgresql/.ssh/authorized_keys
chmod 600 /var/lib/postgresql/.ssh/config
chmod 600 /var/lib/postgresql/.ssh/id_ed25519
chmod 644 /var/lib/postgresql/.ssh/id_ed25519.pub

# Ensure correct permissions on the PostgreSQL data directory
echo "Setting permissions on PostgreSQL data directory..."
chown -R postgres:postgres /var/lib/postgresql/data
chmod 700 /var/lib/postgresql/data

echo "Checking permissions for /var/lib/postgresql/data:"
ls -ld /var/lib/postgresql/data

# Start PostgreSQL
echo "Starting PostgreSQL using the official entrypoint script..."
exec /usr/local/bin/docker-entrypoint.sh postgres "$@"