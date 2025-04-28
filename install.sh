#!/bin/bash

echo "🔧 Jupyter Notebook Docker Setup"

# Full ASCII Art
cat << "EOF"

███████╗██╗░█████╗░░██████╗██╗░██████╗
╚════██║██║██╔══██╗██╔════╝╚█║██╔════╝
░░███╔═╝██║███████║╚█████╗░░╚╝╚█████╗░
██╔══╝░░██║██╔══██║░╚═══██╗░░░░╚═══██╗
███████╗██║██║░░██║██████╔╝░░░██████╔╝
╚══════╝╚═╝╚═╝░░╚═╝╚═════╝░░░░╚═════╝░

███╗░░██╗░█████╗░████████╗███████╗██████╗░░█████╗░░█████╗░██╗░░██╗
████╗░██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██╔══██╗██║░██╔╝
██╔██╗██║██║░░██║░░░██║░░░█████╗░░██████╦╝██║░░██║██║░░██║█████═╝░
██║╚████║██║░░██║░░░██║░░░██╔══╝░░██╔══██╗██║░░██║██║░░██║██╔═██╗░
██║░╚███║╚█████╔╝░░░██║░░░███████╗██████╦╝╚█████╔╝╚█████╔╝██║░╚██╗
╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░╚══════╝╚═════╝░░╚════╝░░╚════╝░╚═╝░░╚═╝
EOF

# Dependency check
check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        echo "❌ $1 is required but not installed. Please install it first."
        exit 1
    fi
}

echo "🔍 Checking dependencies..."
check_dependency docker

# Check Docker daemon
if ! docker info &> /dev/null; then
    echo "❌ Docker daemon is not running or you don't have permissions."
    exit 1
fi

# Defaults
DEFAULT_DOCKER_NAME="jupyter-notebook"
DEFAULT_LOCAL_FOLDER="${PWD}/notebooks"
DEFAULT_HOST_PORT="8888"
WORKDIR="/home/jovyan/work"

validate_port() {
    [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 1 ] && [ "$1" -le 65535 ]
}

validate_directory() {
    mkdir -p "$1" 2>/dev/null && [ -w "$1" ]
}

# Function to read input with a default
read_input() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    local validation_func="$4"

    while true; do
        read -p "🔹 $prompt [$default]: " input
        input="${input:-$default}"

        if [ -z "$validation_func" ] || $validation_func "$input"; then
            eval "$var_name=\"$input\""
            break
        else
            echo "❌ Invalid input: $input"
        fi
    done
}

# Function to get required input (non-empty)
read_required_input() {
    local prompt="$1"
    local var_name="$2"

    while true; do
        read -p "🔹 $prompt: " input
        if [ -n "$input" ]; then
            eval "$var_name=\"$input\""
            break
        else
            echo "❌ This field is required."
        fi
    done
}

# Ask configuration
echo "📝 Configuration:"
read_input "Docker container name" "$DEFAULT_DOCKER_NAME" "DOCKER_NAME"
read_required_input "Username (required)" "NB_USER"

# Set password (required)
echo "🔒 Set a password for the Jupyter Notebook (required):"
check_dependency python3
if ! python3 -c "import notebook" &> /dev/null; then
    echo "Installing notebook Python package..."
    pip3 install notebook > >(tee >(tail -n 5)) 2>&1
fi

# Function to ask for password
ask_password() {
    echo "🔹 Set Jupyter password:"
    check_dependency python3

    # Install jupyter_server if not present
    if ! python3 -c "import jupyter_server.auth" &> /dev/null; then
        echo "⚙️  Installing required Python package 'jupyter_server'..."
        python3 -m pip install --upgrade pip setuptools wheel
        python3 -m pip install jupyter_server
    fi

    HASHED_PASSWORD=$(python3 -c "from jupyter_server.auth import passwd; print(passwd())")
    
    if [[ -z "$HASHED_PASSWORD" ]]; then
        echo "❌ Password hash generation failed. Exiting."
        exit 1
    fi

    echo "✅ Password has been hashed."
}
ask_password

read_input "Local folder to mount" "$DEFAULT_LOCAL_FOLDER" "LOCAL_FOLDER" validate_directory
read_input "Host port" "$DEFAULT_HOST_PORT" "HOST_PORT" validate_port

# Check port availability
if nc -z 127.0.0.1 "$HOST_PORT" &>/dev/null; then
    echo "❌ Port $HOST_PORT is already in use. Please choose another port."
    exit 1
fi

# Create Dockerfile
echo "📦 Creating Dockerfile..."
cat > Dockerfile <<EOF
FROM quay.io/jupyter/base-notebook:latest
EOF

# Create docker-compose.yml
echo "📦 Creating docker-compose.yml..."
# Escape $ signs for docker-compose
ESCAPED_PASSWORD=$(echo "$HASHED_PASSWORD" | sed 's/\$/\$\$/g')

# Create docker-compose.yml
cat > docker-compose.yml <<EOF
services:
  jupyter:
    build: .
    container_name: "${DOCKER_NAME}"
    ports:
      - "${HOST_PORT}:${HOST_PORT}"
    user: "jovyan"  # Must be jovyan
    environment:
      NB_USER: "${NB_USER}"   # Still set the "login" name in environment
      CHOWN_HOME: "yes"
    volumes:
      - "${LOCAL_FOLDER}:${WORKDIR}"
    working_dir: "${WORKDIR}"
    command: >
      jupyter lab
      --ip=0.0.0.0
      --port='${HOST_PORT}'
      --ServerApp.password='${ESCAPED_PASSWORD}'
    restart: unless-stopped
EOF

# Determine Docker Compose command
COMPOSE_CMD="docker compose"
if ! $COMPOSE_CMD version &>/dev/null; then
    COMPOSE_CMD="docker-compose"
fi

# Start container
echo "🚀 Starting Docker container..."
$COMPOSE_CMD up -d --build | tail -n 5

# Final check
if docker ps | grep -q "$DOCKER_NAME"; then
    echo -e "\n✅ Jupyter Notebook is running at: http://localhost:${HOST_PORT}"
    echo "🔒 Password protection is enabled"
    echo "📁 Your notebooks are stored in: ${LOCAL_FOLDER}"
else
    echo -e "\n❌ Failed to start container. Check logs with: docker logs ${DOCKER_NAME}"
fi
