#!/bin/bash

DEFAULT_PATHS=(
    "/etc/redis/redis.conf"
    "/usr/local/etc/redis/redis.conf"
    "/opt/redis/redis.conf"
)

error_exit() {
    echo "Error: $1" >&2
    exit 1
}

extract_password() {
    local file="$1"
    [ ! -f "$file" ] && error_exit "Configuration file not found: $file"
    [ ! -r "$file" ] && error_exit "Cannot read configuration file: $file"
    local password=$(grep -E "^[[:space:]]*requirepass[[:space:]]+" "$file" | awk '{print $2}')
    if [ -z "$password" ]; then
        password=$(grep -E "^[[:space:]]*masterauth[[:space:]]+" "$file" | awk '{print $2}')
    fi
    [ -z "$password" ] && error_exit "No password found in configuration file"
    echo "$password"
}

update_dockerfile() {
    local password="$1"
    local dockerfile="Dockerfile"
    [ ! -f "$dockerfile" ] && error_exit "Dockerfile not found in current directory"

    # Ensure compatibility for both macOS and Linux systems
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|your_redis_password_here|${password}|" "$dockerfile"
    else
        sed -i "s|your_redis_password_here|${password}|" "$dockerfile"
    fi
    echo "Successfully replaced 'your_redis_password_here' in Dockerfile with the Redis password."
}

deploy_docker() {
    echo "Building Docker image..."
    if ! sudo docker build -t codeexport .; then
        error_exit "Docker build failed"
    fi
    echo "Running Docker container..."
    if ! sudo docker run --network host codeexport; then
        error_exit "Docker run failed"
    fi
}

main() {
    local conf_file=""
    if [ $# -eq 1 ]; then
        conf_file="$1"
    else
        for path in "${DEFAULT_PATHS[@]}"; do
            if [ -f "$path" ]; then
                conf_file="$path"
                break
            fi
        done
    fi

    [ -z "$conf_file" ] && error_exit "Could not find redis.conf in default locations. Please provide path as argument."

    local redis_password=$(extract_password "$conf_file")
    echo "Found Redis password: $redis_password"

    # Update the Dockerfile with the extracted password
    update_dockerfile "$redis_password"
    deploy_docker
}

main "$@"
