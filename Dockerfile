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
    apt-get install -y gosu && \
    rm -rf /var/lib/apt/lists/*

# Expose SSH Port
EXPOSE 22

# Copy PostgreSQL Configuration
COPY --chown=postgres:postgres config/postgresql.conf /etc/postgresql/postgresql.conf

# Copy and Set Permissions for the Start Script
COPY start_services.sh /start_services.sh
RUN chmod +x /start_services.sh

# Use the official entrypoint script and default command
ENTRYPOINT ["/start_services.sh"]
CMD ["postgres"]
