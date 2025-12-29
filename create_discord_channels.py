import discord
import os
import pandas as pd
import asyncio
from dotenv import load_dotenv

load_dotenv()

DISCORD_TOKEN = os.getenv("DISCORD_TOKEN")
DISCORD_SERVER_ID = int(os.getenv("DISCORD_SERVER_ID"))
CSV_FILE = 'channels.csv'

intents = discord.Intents.default()
intents.guilds = True
client = discord.Client(intents=intents)

@client.event
async def on_ready():
    print(f"Logged in as {client.user} (ID: {client.user.id})")
    print("------")

    guild = client.get_guild(DISCORD_SERVER_ID)
    
    if not guild:
        print(f"Error: Could not find a server with ID: {DISCORD_SERVER_ID}")
        print("Double-check the ID and ensure the bot is invited to that specific server.")
        await client.close()
        return

    print(f"Connected to server: {guild.name}")

    existing_channels = [channel.name for channel in guild.text_channels]
    print(f"Found {len(existing_channels)} existing text channels.")

    try:
        df = pd.read_csv(CSV_FILE, header=None)
        desired_channels = df[1].astype(str).tolist()
        print(f"Reading {len(desired_channels)} channel names from {CSV_FILE}.")
    except FileNotFoundError:
        print(f"Error: The file '{CSV_FILE}' was not found.")
        await client.close()
        return
    except Exception as e:
        print(f"Error reading {CSV_FILE}: {e}")
        await client.close()
        return

    channels_to_create = [
        name.strip() for name in desired_channels 
        if name.strip().lower().replace(" ", "-") not in existing_channels
    ]

    if not channels_to_create:
        print("All channels from the CSV already exist. Nothing to do.")
    else:
        print(f"Attempting to create {len(channels_to_create)} new channels...")
        for channel_name in channels_to_create:
            try:
                new_channel = await guild.create_text_channel(channel_name)
                print(f"Successfully created: '{new_channel.name}'")
            except discord.Forbidden:
                print(f"Error: Missing 'Manage Channels' permission for '{channel_name}'.")
            except discord.HTTPException as e:
                print(f"HTTP Error on '{channel_name}': {e}")

    print("------")
    print("Task finished. Shutting down bot.")
    await client.close()

if __name__ == "__main__":
    if not DISCORD_TOKEN or not DISCORD_SERVER_ID:
        print("Error: DISCORD_TOKEN and DISCORD_SERVER_ID must be set in your .env file.")
    else:
        try:
            client.run(DISCORD_TOKEN)
        except discord.LoginFailure:
            print("Error: Invalid DISCORD_TOKEN. Please check your credentials.")