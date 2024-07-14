# docker build -t orion6/orion6dev.postgres .
# https://wiki.postgresql.org/wiki/Apt

# We use Kubegres (https://www.kubegres.io/) as a Kubernetes operator for PostgreSQL.
# The operator is based on the official PostgreSQL Docker image.
# We stay close to the PostgreSQL version used in the operator.
FROM postgres:16.3

VOLUME ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

# https://stackoverflow.com/questions/72273216/error-building-custom-docker-image-with-postgres-and-security-updates-configur
ENV DEBIAN_FRONTEND=noninteractive

COPY init.sql /docker-entrypoint-initdb.d/

# https://pypi.org/project/python-magic/
# https://github.com/ahupp/python-magic
# https://askubuntu.com/questions/105652/where-is-the-file-used-by-file1-and-libmagic-to-determine-mime-types
# https://www.garykessler.net/library/magic.html

# I have no idea why this is necessary, but it is: --break-system-packages  
# Neither do I oversee the implications of this.
# https://askubuntu.com/questions/1465218/pip-error-on-ubuntu-externally-managed-environment-%C3%97-this-environment-is-extern

# Set the locale
RUN localedef -i de_DE -c -f UTF-8 -A /usr/share/locale/locale.alias de_DE.UTF-8 
ENV LANG de_DE.UTF-8

# Update apt and install packages
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

# Create the SSH directory and set permissions
RUN mkdir -p /var/lib/postgresql/.ssh && \
    chmod 700 /var/lib/postgresql/.ssh

# Create SSH configuration directory and add default SSH configuration
RUN mkdir -p /etc/ssh && \
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config && \
    echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config && \
    echo "UsePAM yes" >> /etc/ssh/sshd_config && \
    echo "AllowUsers postgres" >> /etc/ssh/sshd_config

# Expose the SSH port
EXPOSE 22

# Copy the custom postgresql.conf from the local 'config' directory to the appropriate place in the container
COPY --chown=postgres:postgres config/postgresql.conf /etc/postgresql.conf

# Start the SSH service and PostgreSQL with the custom configuration
CMD ["sh", "-c", "service ssh start; exec postgres -c config_file=/etc/postgresql.conf"]
