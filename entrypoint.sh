#!/bin/sh
set -e

echo "DEBUG: Starting entrypoint script..."

if [ -f "/etc/matterbridge/matterbridge.env" ]; then
    echo "DEBUG: Loading env from /etc/matterbridge/matterbridge.env"
    set -a
    . /etc/matterbridge/matterbridge.env
    set +a
fi
if [ -f "/app/.env" ]; then
    echo "DEBUG: Loading env from /app/.env"
    set -a
    . /app/.env
    set +a
fi

# Check if SLACK_TOKEN is set
if [ -z "$SLACK_TOKEN" ]; then
    echo "ERROR: SLACK_TOKEN is not set!"
else
    echo "DEBUG: SLACK_TOKEN starts with '$(echo $SLACK_TOKEN | cut -c1-5)'"
fi

# Check if SLACK_APP_TOKEN is set
if [ -z "$SLACK_APP_TOKEN" ]; then
    echo "ERROR: SLACK_APP_TOKEN is not set!"
else
    echo "DEBUG: SLACK_APP_TOKEN starts with '$(echo $SLACK_APP_TOKEN | cut -c1-5)'"
fi

# Check Discord variables
if [ -z "$DISCORD_TOKEN" ]; then
    echo "ERROR: DISCORD_TOKEN is not set!"
else
    echo "DEBUG: DISCORD_TOKEN starts with '$(echo $DISCORD_TOKEN | cut -c1-5)'"
fi

if [ -z "$DISCORD_SERVER_ID" ]; then
    echo "ERROR: DISCORD_SERVER_ID is not set!"
else
    echo "DEBUG: DISCORD_SERVER_ID is '$DISCORD_SERVER_ID'"
fi

TEMPLATE_PATH="/etc/matterbridge/matterbridge.toml"
EXPANDED_TEMPLATE="/etc/matterbridge/matterbridge-expanded.toml"

if [ -f "/app/generate_matterbridge_config.py" ] && [ -f "/app/channels.csv" ]; then
    echo "DEBUG: Expanding gateway list from CSV..."
    python3 /app/generate_matterbridge_config.py \
        --csv /app/channels.csv \
        --template "$TEMPLATE_PATH" \
        --output "$EXPANDED_TEMPLATE"
    TEMPLATE_TO_USE="$EXPANDED_TEMPLATE"
else
    echo "WARN: CSV or generator script missing; using static template"
    TEMPLATE_TO_USE="$TEMPLATE_PATH"
fi

if [ -f "$TEMPLATE_TO_USE" ]; then
    echo "DEBUG: Generating configuration file..."
    envsubst '$SLACK_TOKEN,$SLACK_APP_TOKEN,$DISCORD_TOKEN,$DISCORD_SERVER_ID' < "$TEMPLATE_TO_USE" > /etc/matterbridge/matterbridge-run.toml
else
    echo "ERROR: Template $TEMPLATE_TO_USE not found"
    exit 1
fi


echo "DEBUG: Starting Matterbridge..."
# Try to find matterbridge in PATH, otherwise assume it's in /bin or /usr/bin
if command -v matterbridge >/dev/null 2>&1; then
    exec matterbridge -conf /etc/matterbridge/matterbridge-run.toml
elif [ -f "/bin/matterbridge" ]; then
    exec /bin/matterbridge -conf /etc/matterbridge/matterbridge-run.toml
elif [ -f "/usr/bin/matterbridge" ]; then
    exec /usr/bin/matterbridge -conf /etc/matterbridge/matterbridge-run.toml
else
    echo "ERROR: Could not find matterbridge binary. Listing current directory:"
    ls -la
    echo "Listing /bin:"
    ls -la /bin
    exit 1
fi
