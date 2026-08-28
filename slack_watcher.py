import os
import csv
import subprocess
from dotenv import load_dotenv
from slack_bolt import App
from slack_bolt.adapter.socket_mode import SocketModeHandler

# Load tokens from your existing .env file
load_dotenv()

app = App(token=os.getenv("SLACK_TOKEN"))
CSV_FILE = "channels.csv"

# Fetch the bot's own internal Slack User ID at startup
BOT_USER_ID = app.client.auth_test()["user_id"]

@app.event("message")
def handle_message_events(body, logger):
    print("recieved a message")
    print(body);
    pass

@app.event("member_joined_channel")
def handle_bot_added(event, client):
    # Only trigger if the user joining is THIS bot
    if event.get("user") != BOT_USER_ID:
        return

    channel_id = event.get("channel")
    
    try:
        # Request the readable channel name from the Slack API
        result = client.conversations_info(channel=channel_id)
        channel_name = result["channel"]["name"]
        
        print(f"Detected bot added to new channel: {channel_name}")
        
        # Check if it already exists in the CSV
        existing_channels = []
        if os.path.exists(CSV_FILE):
            with open(CSV_FILE, mode='r') as f:
                reader = csv.reader(f)
                for row in reader:
                    if row:
                        existing_channels.append(row[0])

        if channel_name not in existing_channels:
            print(f"Appending {channel_name} to {CSV_FILE}...")
            with open(CSV_FILE, mode='a', newline='') as f:
                writer = csv.writer(f)
                writer.writerow([channel_name, channel_name])
            
            print("Triggering Matterbridge service restart...")
            # Restart the docker container to apply changes
            subprocess.run(["docker", "restart", "matterbridge-service"], check=True)
            print("Restart complete. New channel is now bridged.")
        else:
            print("Channel already exists in CSV. No action taken.")

    except Exception as e:
        print(f"Error processing new channel integration: {e}")

if __name__ == "__main__":
    print("Slacker started");
    print(f"Starting Slack Auto-Watcher. Bot ID: {BOT_USER_ID}")
    handler = SocketModeHandler(app, os.getenv("SLACK_APP_TOKEN"))
    handler.start()