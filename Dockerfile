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

# Create SSH Directory and Set Permissions
RUN mkdir -p /var/lib/postgresql/.ssh && \
    chmod 700 /var/lib/postgresql/.ssh

# SSH Configuration
RUN mkdir -p /etc/ssh && \
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config && \
    echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config && \
    echo "UsePAM yes" >> /etc/ssh/sshd_config && \
    echo "AllowUsers postgres" >> /etc/ssh/sshd_config

# Expose SSH Port
EXPOSE 22

# Copy PostgreSQL Configuration
COPY --chown=postgres:postgres config/postgresql.conf /etc/postgresql/postgresql.conf

# Ensure data directory exists and has correct permissions
RUN mkdir -p /var/lib/postgresql/data && \
    chown -R postgres:postgres /var/lib/postgresql && \
    chmod 700 /var/lib/postgresql/data

# Copy and Set Permissions for the Start Script
COPY start_services.sh /start_services.sh
RUN chmod +x /start_services.sh

# Override entrypoint to use the provided script
ENTRYPOINT ["/start_services.sh"]

# Use the default command provided by the official PostgreSQL image
CMD ["postgres"]
