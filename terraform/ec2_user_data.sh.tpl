#!/bin/bash
set -euo pipefail

# Install prerequisites
apt-get update
apt-get install -y docker.io git awscli jq curl
systemctl enable docker
systemctl start docker

# Install Docker Compose v2 standalone binary
curl -SL https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-linux-x86_64 \
    -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
# Symlink so 'docker-compose' is on root's PATH
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Allow ubuntu user to run Docker
usermod -aG docker ubuntu

# Export AWS region for aws CLI
export AWS_DEFAULT_REGION=${aws_region}

# Clone or update the pipeline repo
APP_DIR=/home/ubuntu/app
REPO=https://github.com/ranovoxo/movie-data-pipeline-cloud.git
mkdir -p "$${APP_DIR}"
chown ubuntu:ubuntu "$${APP_DIR}"

if [ ! -d "$${APP_DIR}/.git" ]; then
    sudo -u ubuntu git clone "$${REPO}" "$${APP_DIR}"
else
    cd "$${APP_DIR}"
    sudo -u ubuntu git pull origin main
fi
cd "$${APP_DIR}"

# Retry helper for SSM SecureString fetches
fetch() {
    local param="$1"
    local value
    until value=$(aws ssm get-parameter --name "$param" --with-decryption \
        --query Parameter.Value --output text 2>/dev/null); do
        echo "Waiting for parameter $param…" >&2
        sleep 5
    done
    echo "$value"
}

# Write .env with decrypted values

# RDS host & port come straight from Terraform
POSTGRES_HOST=${postgres_host}
POSTGRES_PORT=${postgres_port}
export POSTGRES_HOST POSTGRES_PORT

# Fetching parameters from parameter store
export POSTGRES_USER="$(fetch /movie-app/prod/postgres/POSTGRES_USER)"
export POSTGRES_PW="$(fetch /movie-app/prod/postgres/POSTGRES_PW)"
export POSTGRES_DB="$(fetch /movie-app/prod/postgres/POSTGRES_DB)"


SQL_ALCHEMY_CONN="postgresql://$POSTGRES_USER:$POSTGRES_PW@${postgres_host}:${postgres_port}/$POSTGRES_DB"
export SQL_ALCHEMY_CONN

export PGADMIN_DEFAULT_EMAIL="$(fetch /movie-app/prod/pgadmin/PGADMIN_DEFAULT_EMAIL)"
export PGADMIN_DEFAULT_PASSWORD="$(fetch /movie-app/prod/pgadmin/PGADMIN_DEFAULT_PASSWORD)"
export TABLEAU_EXPORT_PATH="$(fetch /movie-app/prod/export/TABLEAU_EXPORT_PATH)"

# Bring up the Docker Compose services
docker-compose up -d