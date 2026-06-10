#!/bin/sh
set -e

CONTAINER_NAME="matterbridge-service"
IMAGE_NAME="custom-image"
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_PATH="$CURRENT_DIR/$(basename "$0")"
LOG_FILE="$CURRENT_DIR/service_monitor.log"

run_check() {
    # Check if the container is currently active
    if [ -z "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
        echo "$(date): Container $CONTAINER_NAME is down. Attempting restart..." >> "$LOG_FILE"
        
        # Attempt to boot the existing container context
        docker start "$CONTAINER_NAME" || true
        sleep 10

        # Re-evaluate runtime status
        if [ -z "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
            echo "$(date): CRITICAL - Restart failed. Dumping logs and halting container process." >> "$LOG_FILE"
            docker logs "$CONTAINER_NAME" >> "$LOG_FILE" 2>&1
            docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
        else
            echo "$(date): Recovery successful. Container is running." >> "$LOG_FILE"
        fi
    fi
}

run_deploy() {
    echo "Initiating image build sequence..."
    docker build -t "$IMAGE_NAME" "$CURRENT_DIR"

    echo "Clearing legacy container dependencies..."
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

    echo "Launching containerized service..."
    docker run -d \
      --name "$CONTAINER_NAME" \
      --env-file "$CURRENT_DIR/.env" \
      -v "$CURRENT_DIR/channels.csv:/app/channels.csv" \
      "$IMAGE_NAME"

    # if [ -f "$CURRENT_DIR/slack_watcher.py" ]; then
    #     echo "Configuring host-side virtual environment..."
    #     if [ ! -d "$CURRENT_DIR/venv" ]; then
    #         python3 -m venv "$CURRENT_DIR/venv"
    #     fi
    #     "$CURRENT_DIR/venv/bin/pip" install --quiet slack_bolt python-dotenv
        
    #     echo "Terminating conflicting watcher instances..."
    #     pkill -f "slack_watcher.py" || true
        
    #     echo "Executing channel watcher background process..."
    #     cd "$CURRENT_DIR"
    #     nohup "$CURRENT_DIR/venv/bin/python3" "slack_watcher.py" > "watcher.log" 2>&1 &
    # fi


    echo "Registering daily crontab entry..."
    # Extracts existing crontab items, purges old references to this script, and injects the new absolute path execution line
    (crontab -l 2>/dev/null | grep -v "$CONTAINER_NAME --check" || true; echo "0 0 * * * $SCRIPT_PATH --check") | crontab -
    
    echo "Deployment completed successfully. Health check scheduled for 00:00 daily."
}

case "$1" in
    --check)
        run_check
        ;;
    *)
        run_deploy
        ;;
    esac