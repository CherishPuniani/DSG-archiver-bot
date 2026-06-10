## How to find keys?

- `Slack Token` can be found when making the app as the bot token after giving it bot scope
- `Slack App` can be found when making the app itself
- `Discord Token` is the bot from discord side made from the discord developer dashboard
- `Discord Server ID` can be found by activating developer mode in discord and getting server id from its settings.

## Installation Steps

Run `host.sh` file which will automatically build the image and then host it. it will then setup a cronjob to track if its running or not. and store it in a log.

```bash
# after including .env file
chmod +x host.sh
./host.sh
```

to view logs and check integration run command:

```bash
docker logs matterbridge-service
```

## Todo

- make the manual csv management into automated system where the

```

```
