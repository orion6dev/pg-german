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

4. Run a container from the image:

   ```bash
   docker run -d --name my-postgres-container \
     -v /path/to/ssh-keys/id_rsa.pub:/var/lib/postgresql/.ssh/authorized_keys \
     -v /path/to/init.sql:/docker-entrypoint-initdb.d/init.sql \
     -v /path/to/config/postgresql.conf:/etc/postgresql.conf \
     -p 5432:5432 -p 2222:22 my-postgresql-app
   ```

Alternatively, you can pull the pre-built image from GitHub Container Registry and use Docker Compose:

```bash
docker pull ghcr.io/orion6dev/pg-german:dev

docker compose -f support/docker-compose-db.yml up
```

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
