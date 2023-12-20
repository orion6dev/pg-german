# PostgreSQL Docker Image Repository

![PostgreSQL Logo](https://wiki.postgresql.org/images/3/30/PostgreSQL_logo.3colors.120x120.png)

Welcome to the PostgreSQL Docker Image Repository! This repository hosts a Docker image designed for running PostgreSQL, enhanced with additional tools and configurations. This image is built upon the official PostgreSQL image, ensuring compatibility and reliability.

## Table of Contents

- [About PostgreSQL](#about-postgresql)
- [Docker Image Overview](#docker-image-overview)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Usage Examples](#usage-examples)
- [Contributing](#contributing)
- [License](#license)

## About PostgreSQL

PostgreSQL is a powerful,
open-source relational database management system known for its robust features and scalability.
It is widely used for a variety of applications and is known for its reliability and extensibility.

Learn more about PostgreSQL [here](https://www.postgresql.org/).

## Docker Image Overview

Our Docker image is based on the official PostgreSQL Docker image, with the addition of various tools and configurations. Here's what you'll find in this image:

- **Base Image**: [PostgreSQL 16.0](https://hub.docker.com/_/postgres)
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
   docker run -d -p 5432:5432 --name my-postgresql-container my-postgresql-app
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
create or replace language "plpython3u"; 

create or replace function mimemagic(data bytea) returns text as
$$
import magic
return magic.from_buffer(data, mime=True)
$$ language plpython3u;

create or replace function compress(data bytea) returns bytea as
$$
import zlib
return zlib.compress(data)
$$ language plpython3u;

create or replace function decompress(data bytea) returns bytea as
$$
import zlib
return zlib.decompress(data)
$$ language plpython3u;
```

## Contributing

We welcome contributions from the community! If you have suggestions, bug reports, or improvements, please feel free to open issues or submit pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Thank you for choosing our PostgreSQL Docker image. We hope it serves your database needs effectively. If you have any questions or need assistance, please don't hesitate to reach out to us through GitHub issues.

Happy database management!
