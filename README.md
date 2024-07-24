# PostgreSQL Docker Image Repository

![PostgreSQL Logo](https://wiki.postgresql.org/images/3/30/PostgreSQL_logo.3colors.120x120.png)

Welcome to the PostgreSQL Docker Image Repository! This repository hosts a Docker image designed for running PostgreSQL, enhanced with additional tools and configurations for improved functionality and flexibility.

## Table of Contents

- [About PostgreSQL](#about-postgresql)
- [Docker Image Overview](#docker-image-overview)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Usage Examples](#usage-examples)
- [Configuring SSH Keys](#configuring-ssh-keys)
- [Custom Configuration](#custom-configuration)
- [Using pgBackRest](#using-pgbackrest)
- [Contributing](#contributing)
- [License](#license)

## About PostgreSQL

PostgreSQL is a powerful, open-source relational database management system known for its robust features and scalability. It is widely used for a variety of applications and is known for its reliability and extensibility.

Learn more about PostgreSQL [here](https://www.postgresql.org/).

## Docker Image Overview

Our Docker image is based on the official PostgreSQL Docker image, with the addition of various tools and configurations to enhance its capabilities. Here’s what you’ll find in this image:

- **Base Image**: [PostgreSQL 16.3](https://hub.docker.com/_/postgres)
  - This image provides a PostgreSQL database server, configured to be used as a standalone database instance.
- **Volume Mounts**: This image sets up volume mounts for `/etc/postgresql`, `/var/log/postgresql`, and `/var/lib/postgresql`. These volumes allow you to persist configuration, logs, and database data, ensuring data integrity and easy management.
- **Custom Initialization Script**: The image includes an `init.sql` script placed in `/docker-entrypoint-initdb.d/`. This script will be executed during the database initialization, allowing you to perform custom setup tasks.
- **Additional Packages**: The image installs several additional packages, including `libmagic1`, `restic`, `ssh-client`, `python3-pip`, `pipx`, `python3-dev`, and `postgresql-plpython3-16`, expanding the image's capabilities.
- **Locale Configuration**: Locale settings are configured to ensure correct character encoding.
- **Python Libraries**: Python libraries such as `rsa` and `python-magic` are installed to provide additional functionality for PostgreSQL extensions or custom scripts.

## Prerequisites

Before using this Docker image, ensure you have the following prerequisites installed:

- [Docker](https://docs.docker.com/get-docker/): Install Docker to build and run containers.
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git): Install Git to clone this repository and access Dockerfiles.

## Getting Started

To get started with our PostgreSQL Docker image, follow these steps:

1. Clone this repository to your local machine:

   ```bash
   git clone https://github.com/orion6dev/pg-german.git
   ```

2. Navigate to the repository directory:

   ```bash
   cd pg-german
   ```

3. Build the Docker image using the provided Dockerfile:

   ```bash
   docker build -t my-postgresql-app .
   ```

4. Run the database:

```bash
docker compose -f support/docker-compose-db.yml up
```

Now you can attach to the network multitool

```bash
docker exec -it network-multitool /bin/bash
```

In the network multitool you can either ping the database server `ping postgres` or connect to the database server using ssh `ssh postgres@postgres`

Now, your PostgreSQL database server should be accessible at `localhost:5432`.

## Usage Examples

Here are a few examples of how you can use our PostgreSQL Docker image:

### Example 1: Custom Initialization Script

You can use the `init.sql` script to perform custom setup tasks during database initialization. Place your SQL commands in this script.

### Example 2: Installing PostgreSQL Extensions

You can extend PostgreSQL by installing extensions using `CREATE EXTENSION` commands within your SQL scripts.

### Example 3: Running Python Scripts

With Python libraries like `python-magic` installed, you can run custom Python scripts within your PostgreSQL environment.

For example:

```sql
CREATE OR REPLACE LANGUAGE plpython3u;

CREATE OR REPLACE FUNCTION mimemagic(data bytea) RETURNS text AS
$$
import magic
return magic.from_buffer(data, mime=True)
$$ LANGUAGE plpython3u;

CREATE OR REPLACE FUNCTION compress(data bytea) RETURNS bytea AS
$$
import zlib
return zlib.compress(data)
$$ LANGUAGE plpython3u;

CREATE OR REPLACE FUNCTION decompress(data bytea) RETURNS bytea AS
$$
import zlib
return zlib.decompress(data)
$$ LANGUAGE plpython3u;
```

## Configuring SSH Keys

Ensure you have an SSH key pair on your backup host. Copy the public key to the host directory that you will mount into the container.

Generate an SSH key pair if you don’t have one:

```bash
ssh-keygen -t rsa -b 4096 -C "pgbackrest@backuphost"
```

Copy the public key to the directory you will mount:

```bash
cp ~/.ssh/id_rsa.pub /path/to/ssh-keys/
```

## Custom Configuration

Your custom PostgreSQL configuration file should be placed in the directory you will mount to the container. For example, create a `postgresql.conf` file with your desired settings and place it in `/path/to/config/`.

## Using pgBackRest

pgBackRest is included in the image for backup and restore operations. Ensure your `pgbackrest.conf` is properly configured and accessible.

### Example `pgbackrest.conf`:

```ini
[main-db]
pg1-path=/var/lib/postgresql/data
pg1-port=5432
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2

[global]
repo1-cipher-pass=<encryption_passphrase>
repo1-cipher-type=aes-256-cbc

[global:archive-push]
compress-level=3
```

Place this configuration file in a suitable location, accessible to your pgBackRest commands.

## Sample Commands

### Running a Backup

To perform a backup, execute the following command from your pgBackRest host:

```sh
pgbackrest --stanza=main-db backup
```

### Restoring a Backup

To restore a backup, use:

```sh
pgbackrest --stanza=main-db restore
```

### Checking Backup Status

To check the status of your backups, run:

```sh
pgbackrest --stanza=main-db check
```

## Monitoring and Logs

You can view logs for PostgreSQL and pgBackRest within the container to monitor the status of your database and backup operations.

### Accessing PostgreSQL Logs

To view PostgreSQL logs, you can attach to the running container or use Docker logs:

```sh
docker logs my-postgres-container
```

### Accessing SSH

To access the container via SSH:

```sh
ssh -i /path/to/private/key -p 2222 postgres@<container-host-ip>
```

Ensure you replace `<container-host-ip>` with the actual IP address of the host running the container.

## Contributing

We welcome contributions from the community! If you have suggestions, bug reports, or improvements, please feel free to open issues or submit pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Thank you for choosing our PostgreSQL Docker image. We hope it serves your database needs effectively. If you have any questions or need assistance, please don't hesitate to reach out to us through GitHub issues.

Happy database management!

```bash
docker run --rm -it \
    -e BACKREST_UID=1001 \
    -e BACKREST_GID=1001 \
    -v ${PWD}/support/test-ssh/id_ed25519_test:/home/pgbackrest/.ssh/id_ed25519_test \
    -v ${PWD}/support/test-ssh/id_ed25519_test.pub:/home/pgbackrest/.ssh/id_ed25519_test.pub \
    -v ${PWD}/support/pgbackrest/pgbackrest:/etc/pgbackrest/pgbackrest \
    -v ${PWD}/pgbackrest/backup:/var/lib/pgbackrest \
    --network support_default \
    woblerr/pgbackrest:2.52 /bin/bash -c "chmod 600 /home/pgbackrest/.ssh/id_ed25519_test && chmod 644 /home/pgbackrest/.ssh/id_ed25519_test.pub && /bin/bash"
```

```powershell
docker run --rm -it `
    -e BACKREST_UID=1001 `
    -e BACKREST_GID=1001 `
    -v ${PWD}/support/test-ssh/pgbackrest/:/home/pgbackrest/.ssh/ `
    -v ${PWD}/support/pgbackrest/pgbackrest.conf:/etc/pgbackrest/pgbackrest.conf `
    -v ${PWD}/pgbackrest/backup:/var/lib/pgbackrest `
    --network support_default `
    --name pgbackrest `
    woblerr/pgbackrest:2.52 /bin/bash -c "chmod 600 /home/pgbackrest/.ssh/id_ed25519; chmod 600 /home/pgbackrest/.ssh/config; chmod 600 /home/pgbackrest/.ssh/authorized_keys; chmod 644 /home/pgbackrest/.ssh/id_ed25519.pub; /bin/bash"
```

pgbackrest --stanza=main-db --log-level-console=info stanza-create 

Sure, here's a detailed chapter on how to map an `.ssh` directory and SSH into the PostgreSQL container:

# Mapping an `.ssh` Directory and SSHing into the PostgreSQL Container

This chapter will guide you through the steps to map an `.ssh` directory to your PostgreSQL Docker container and how to SSH into the container using the mapped SSH keys. This setup is particularly useful for secure and convenient access to your containerized PostgreSQL instance.

## Prerequisites

Before proceeding, ensure you have the following:
- Docker installed on your system.
- Basic knowledge of Docker and Docker Compose.
- SSH keys generated on your local system. If not, you can generate them using `ssh-keygen`.

## Step 1: Directory Structure

Ensure your project directory has the following structure:

```
your-project/
├── docker-compose.yml
├── Dockerfile
├── start_services.sh
└── test-ssh/
    └── postgres/
        ├── authorized_keys
        ├── config
        ├── id_ed25519_test
        └── id_ed25519_test.pub
```

- **authorized_keys**: Contains the public keys allowed to SSH into the container.
- **config**: SSH client configuration file.
- **id_ed25519_test**: Private SSH key.
- **id_ed25519_test.pub**: Public SSH key.

## Step 2: Dockerfile

Your `Dockerfile` should install the necessary packages and copy the `start_services.sh` script. Here is an example:

```Dockerfile
# Base Image
FROM postgres:16.3

# Declare volumes
VOLUME ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

# Environment Variable
ENV DEBIAN_FRONTEND=noninteractive

# Copy initialization script
COPY init.sql /docker-entrypoint-initdb.d/

# Locale Setting
RUN localedef -i de_DE -c -f UTF-8 -A /usr/share/locale/locale.alias de_DE.UTF-8
ENV LANG=de_DE.UTF-8

# Package Installation
RUN apt-get update && \
    apt-get install -y \
    pgbackrest \
    libmagic1 \
    restic \
    openssh-server \
    python3-pip \
    pipx \
    python3-dev \
    postgresql-plpython3-16 && \
    pip3 install --break-system-packages rsa python-magic && \
    rm -rf /var/lib/apt/lists/*

# Expose SSH Port
EXPOSE 22

# Copy PostgreSQL Configuration
COPY --chown=postgres:postgres config/postgresql.conf /etc/postgresql/postgresql.conf

# Create SSH directory and set permissions
RUN mkdir -p /home/postgres/.ssh && \
    chown -R postgres:postgres /home/postgres/.ssh && \
    chmod 700 /home/postgres/.ssh

# Copy and Set Permissions for the Start Script
COPY start_services.sh /start_services.sh
RUN chmod +x /start_services.sh

# Use the official entrypoint script and default command
ENTRYPOINT ["/start_services.sh"]
CMD ["postgres"]
```

## Step 3: start_services.sh

The `start_services.sh` script sets the permissions for the SSH directory and starts the services:

```bash
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
chown -R postgres:postgres /home/postgres/.ssh
chmod 700 /home/postgres/.ssh
chmod 600 /home/postgres/.ssh/authorized_keys
chmod 600 /home/postgres/.ssh/config
chmod 600 /home/postgres/.ssh/id_ed25519_test
chmod 644 /home/postgres/.ssh/id_ed25519_test.pub

# Ensure correct permissions on the PostgreSQL data directory
echo "Setting permissions on PostgreSQL data directory..."
chown -R postgres:postgres /var/lib/postgresql/data
chmod 700 /var/lib/postgresql/data

# Check if the permissions were set correctly
echo "Checking permissions for /home/postgres/.ssh:"
ls -l /home/postgres/.ssh

echo "Checking permissions for /var/lib/postgresql/data:"
ls -ld /var/lib/postgresql/data

# Start PostgreSQL
echo "Starting PostgreSQL using the official entrypoint script..."
exec /usr/local/bin/docker-entrypoint.sh postgres "$@"

entry_status=$?
if [ $entry_status -ne 0 ]; then
    echo "Failed to start PostgreSQL entrypoint with status: $entry_status"
    exit $entry_status
else
    echo "PostgreSQL entrypoint started successfully."
fi
```

## Step 4: Docker Compose Configuration

Configure your `docker-compose.yml` to map the `.ssh` directory and use the custom `start_services.sh` script:

```yaml
version: '3.8'

services:
  network-multitool:
    image: wbitt/network-multitool:extra
    container_name: network-multitool
    volumes:
      - ./test-ssh/postgres/:/home/root/.ssh/
    user: "root:root"
    command: /bin/sh -c "\
      chown -R root:root /usr/share/nginx/html && \
      chown -R root:root /var/lib/nginx/logs && \
      chown -R root:root /home/root/.ssh && \
      chmod 700 /home/root/.ssh && \
      chmod 600 /home/root/.ssh/authorized_keys && \
      chmod 600 /home/root/.ssh/config && \
      chmod 600 /home/root/.ssh/id_ed25519_test && \
      chmod 644 /home/root/.ssh/id_ed25519_test.pub && \
      nginx -g 'daemon off;'"

  postgres:
    image: ghcr.io/orion6dev/pg-german:local
    container_name: postgres
    restart: on-failure
    healthcheck:
      test: [ "CMD-SHELL", "pg_isready -U postgres" ]
      interval: 5s
      timeout: 5s
      retries: 5
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=test*12*
      - POSTGRES_DB=postgres
      - POSTGRES_HOST=postgres
      - POSTGRES_PORT=5432
      - POSTGRES_SCHEMA=public
      - POSTGRES_SSLMODE=Disable
    volumes:
      - postgresql-etc:/etc/postgresql
      - postgresql-log:/var/log/postgresql
      - postgresql-lib:/var/lib/postgresql
      - postgresql-data:/var/lib/postgresql/data
      - ./test-ssh/postgres/:/home/postgres/.ssh/
    user: "root:root"
    entrypoint: ["/start_services.sh"]

volumes:
  postgresql-etc:
  postgresql-log:
  postgresql-lib:
  postgresql-data:
```

## Step 5: SSH into the PostgreSQL Container

To SSH into the PostgreSQL container, follow these steps:

1. **Start the Docker Compose Services**:
    ```sh
    docker-compose up -d
    ```

2. **Get the Container ID**:
    ```sh
    docker ps
    ```

3. **SSH into the Container**:
    Use the private key to SSH into the container:
    ```sh
    ssh -i ./test-ssh/postgres/id_ed25519_test postgres@<container-ip>
    ```

   - Replace `<container-ip>` with the IP address of the PostgreSQL container. You can find it using:
     ```sh
     docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container-id>
     ```

   Alternatively, you can SSH into the container using its name if the SSH configuration allows it:
    ```sh
    ssh -i ./test-ssh/postgres/id_ed25519_test postgres@postgres
    ```

   Ensure the `config` file in your `.ssh` directory is properly configured to allow connections by hostnames or IP addresses.

## Conclusion

By following these steps, you should be able to map an `.ssh` directory to your PostgreSQL Docker container and SSH into it securely. This setup provides a convenient and secure method to access your containerized PostgreSQL instance for management and troubleshooting.