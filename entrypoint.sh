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

echo "DEBUG: Generating configuration file..."
envsubst '$SLACK_TOKEN,$SLACK_APP_TOKEN,$DISCORD_TOKEN,$DISCORD_SERVER_ID' < /etc/matterbridge/matterbridge.toml > /etc/matterbridge/matterbridge-run.toml


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
