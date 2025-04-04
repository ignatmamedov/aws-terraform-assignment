#!/bin/bash
#
# Usage:
#  build - Create docker container(s) for the application
#  run   - Run the application as container(s)
#  stop  - Stop the container(s)

set -e

if [ $# -eq 0 ]; then
    echo "No command provided. Usage: $0 {build|run|stop}"
    exit 1
fi

case "$1" in
    build)
        echo "Building containers..."
        docker-compose build
        ;;
    run)
        echo "Starting containers..."
        docker-compose up -d
        ;;
    stop)
        echo "Stopping containers..."
        docker-compose down
        ;;
    *)
        echo "Invalid command: $1"
        echo "Usage: $0 {build|run|stop}"
        exit 1
        ;;
esac
