# Stage 1: Build the Go backup service
FROM golang:latest AS builder
COPY ./backup-service /build
WORKDIR /build
RUN go build .

# Stage 2: Final image with MariaDB and required tools
FROM mariadb:10.10

# Install dependencies
RUN apt update && \
    apt install -y bzip2 curl && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt update && \
    apt install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Copy H5P backup scripts
COPY create create-logs restore repair /usr/local/bin/

# Copy compiled Go backup service
COPY --from=builder /build/docker-h5p-backup /usr/local/bin/

# Set permissions and create backup directory
RUN chmod +x /usr/local/bin/* && \
    ln -s /usr/local/bin/create /usr/local/bin/backup && \
    mkdir /backup

# Define environment variable for versioning
ENV H5P_BACKUP_VERSION=1.0.0

ENTRYPOINT [ "" ]
