# Notification Channel Setup

## Overview
**Title:** Notification Channel Integration
**Author:** Claude / System Owner
**Status:** Template
**Last Updated:** 2026-03-26

## Problem
The agent system needs a way to notify the system owner about:
- Health alerts (service down, disk full, OOM)
- Task completions and daily digests
- Security events (failed logins, CVE alerts)
- Agent escalations requiring human input

## Goals
- At least one notification channel configured and tested
- Agents can send messages programmatically
- Message formatting supports structured data (status, alerts, reports)
- Owner receives notifications on mobile device

## Out of Scope
- Two-way agent interaction via chat (separate spec)
- Voice notifications
- Multi-user notification routing

---

## Option A: Telegram Bot

Telegram is lightweight, has a simple API, and works well for bot notifications. Recommended for personal/small-team use.

### Step 1: Create a Bot via BotFather
1. Open Telegram, search for `@BotFather`
2. Send `/newbot`
3. Choose a name (e.g., "My Server Agent")
4. Choose a username (e.g., `my_server_agent_bot`)
5. Save the bot token -- this is your `{{TELEGRAM_BOT}}`

### Step 2: Get Your Chat ID
```bash
# Send a message to your bot in Telegram first, then:
curl -s "https://api.telegram.org/bot{{TELEGRAM_BOT}}/getUpdates" | jq '.result[0].message.chat.id'
# Save this value as {{TELEGRAM_USER_ID}}
```

### Step 3: Send a Test Message
```bash
curl -s -X POST "https://api.telegram.org/bot{{TELEGRAM_BOT}}/sendMessage" \
    -d "chat_id={{TELEGRAM_USER_ID}}" \
    -d "text=Hello from OpenClaw Governor!" \
    -d "parse_mode=Markdown"
```

### Notification Script (`/opt/openclaw/scripts/notify_telegram.sh`)
```bash
#!/bin/bash
# Send a notification via Telegram
# Usage: notify_telegram.sh "message text"

BOT_TOKEN="{{TELEGRAM_BOT}}"
CHAT_ID="{{TELEGRAM_USER_ID}}"
MESSAGE="$1"

if [ -z "$MESSAGE" ]; then
    echo "Usage: $0 <message>"
    exit 1
fi

curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=${MESSAGE}" \
    -d "parse_mode=Markdown" \
    > /dev/null

echo "Notification sent."
```

### Formatted Alert Example
```bash
# Health alert with Markdown formatting
/opt/openclaw/scripts/notify_telegram.sh "$(cat <<'MSG'
*ALERT: Service Down*
---
Service: `local-inference`
Status: DOWN
Time: $(date '+%Y-%m-%d %H:%M:%S')
Action: Auto-restart attempted

_Sent by alert-relay agent_
MSG
)"
```

### OpenClaw Integration
Add Telegram as a plugin in `openclaw.json`:
```json
{
  "plugins": {
    "telegram": {
      "enabled": true,
      "botToken": "{{TELEGRAM_BOT}}",
      "chatId": "{{TELEGRAM_USER_ID}}",
      "groupPolicy": "allowlist"
    }
  }
}
```

---

## Option B: Discord Webhook

Discord webhooks are simple to set up and support rich embeds. Good for team environments.

### Step 1: Create a Webhook
1. Open Discord, go to your server
2. Server Settings > Integrations > Webhooks
3. Click "New Webhook"
4. Name it (e.g., "Server Alerts")
5. Choose a channel
6. Copy the webhook URL

### Step 2: Send a Test Message
```bash
DISCORD_WEBHOOK="https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN"

curl -s -X POST "$DISCORD_WEBHOOK" \
    -H "Content-Type: application/json" \
    -d '{
        "content": "Hello from OpenClaw Governor!",
        "username": "alert-relay"
    }'
```

### Notification Script (`/opt/openclaw/scripts/notify_discord.sh`)
```bash
#!/bin/bash
# Send a notification via Discord webhook
# Usage: notify_discord.sh "message text"

WEBHOOK_URL="https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN"
MESSAGE="$1"

if [ -z "$MESSAGE" ]; then
    echo "Usage: $0 <message>"
    exit 1
fi

curl -s -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "{
        \"content\": \"${MESSAGE}\",
        \"username\": \"alert-relay\"
    }" \
    > /dev/null

echo "Notification sent."
```

### Rich Embed Example
```bash
curl -s -X POST "$DISCORD_WEBHOOK" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "alert-relay",
        "embeds": [{
            "title": "Service Health Alert",
            "color": 16711680,
            "fields": [
                {"name": "Service", "value": "local-inference", "inline": true},
                {"name": "Status", "value": "DOWN", "inline": true},
                {"name": "Action", "value": "Auto-restart attempted"}
            ],
            "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
        }]
    }'
```

---

## Option C: Slack Incoming Webhook

Slack webhooks integrate well with team workflows and support Block Kit formatting.

### Step 1: Create an Incoming Webhook
1. Go to https://api.slack.com/apps
2. Create a new app (or use existing)
3. Enable "Incoming Webhooks"
4. Add a new webhook to a channel
5. Copy the webhook URL

### Step 2: Send a Test Message
```bash
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

curl -s -X POST "$SLACK_WEBHOOK" \
    -H "Content-Type: application/json" \
    -d '{
        "text": "Hello from OpenClaw Governor!",
        "username": "alert-relay",
        "icon_emoji": ":robot_face:"
    }'
```

### Notification Script (`/opt/openclaw/scripts/notify_slack.sh`)
```bash
#!/bin/bash
# Send a notification via Slack webhook
# Usage: notify_slack.sh "message text"

WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
MESSAGE="$1"

if [ -z "$MESSAGE" ]; then
    echo "Usage: $0 <message>"
    exit 1
fi

curl -s -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "{
        \"text\": \"${MESSAGE}\",
        \"username\": \"alert-relay\"
    }" \
    > /dev/null

echo "Notification sent."
```

### Block Kit Example
```bash
curl -s -X POST "$SLACK_WEBHOOK" \
    -H "Content-Type: application/json" \
    -d '{
        "blocks": [
            {
                "type": "header",
                "text": {"type": "plain_text", "text": "Service Health Alert"}
            },
            {
                "type": "section",
                "fields": [
                    {"type": "mrkdwn", "text": "*Service:*\n`local-inference`"},
                    {"type": "mrkdwn", "text": "*Status:*\nDOWN"},
                    {"type": "mrkdwn", "text": "*Action:*\nAuto-restart attempted"},
                    {"type": "mrkdwn", "text": "*Time:*\n'$(date '+%Y-%m-%d %H:%M:%S')'"}
                ]
            }
        ]
    }'
```

---

## Universal Notification Wrapper

Create a single script that dispatches to whichever channel is configured:

### `/opt/openclaw/scripts/notify.sh`
```bash
#!/bin/bash
# Universal notification dispatcher
# Usage: notify.sh <level> "message"
# Levels: info, warn, alert, critical

LEVEL="${1:-info}"
MESSAGE="$2"
CHANNEL="${NOTIFY_CHANNEL:-telegram}"  # Set in environment or .env

if [ -z "$MESSAGE" ]; then
    echo "Usage: $0 <level> <message>"
    exit 1
fi

PREFIX=""
case "$LEVEL" in
    info)     PREFIX="[INFO]" ;;
    warn)     PREFIX="[WARNING]" ;;
    alert)    PREFIX="[ALERT]" ;;
    critical) PREFIX="[CRITICAL]" ;;
esac

FULL_MESSAGE="$PREFIX $MESSAGE"

case "$CHANNEL" in
    telegram) /opt/openclaw/scripts/notify_telegram.sh "$FULL_MESSAGE" ;;
    discord)  /opt/openclaw/scripts/notify_discord.sh "$FULL_MESSAGE" ;;
    slack)    /opt/openclaw/scripts/notify_slack.sh "$FULL_MESSAGE" ;;
    *)        echo "Unknown channel: $CHANNEL" ; exit 1 ;;
esac
```

### Integration with Health Check
Add to the watchdog health check script:
```bash
# In healthcheck.sh, after detecting a service is down:
if [ "$INFERENCE_STATUS" = "DOWN" ]; then
    /opt/openclaw/scripts/notify.sh alert "Inference server is DOWN - auto-restart attempted"
fi
```

## Acceptance Criteria

- [ ] At least one notification channel configured
- [ ] Test message successfully delivered
- [ ] Notification script works from command line
- [ ] Health check alerts route to notification channel
- [ ] Agent can trigger notifications programmatically
- [ ] Formatted messages render correctly (Markdown/embeds/blocks)

## Security Notes
- Store bot tokens and webhook URLs in environment variables or `.env` files, never in scripts
- Restrict webhook URLs -- if leaked, anyone can post to your channel
- For Telegram: use allowlist group policy to prevent unauthorized commands
- Rotate tokens periodically
