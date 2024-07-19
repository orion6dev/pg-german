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

# Starting PostgreSQL service as the postgres user
echo "Starting PostgreSQL service as non-root user..."
su - postgres -c "/usr/lib/postgresql/16/bin/postgres -D /var/lib/postgresql/data -c config_file=/etc/postgresql.conf" &
postgres_status=$?
if [ $postgres_status -ne 0 ]; then
    echo "Failed to start PostgreSQL service with status: $postgres_status"
    exit $postgres_status
else
    echo "PostgreSQL service started successfully."
fi

# Wait for any process to exit
wait -n

# Exit with the status of the process that exited first
exit $?
