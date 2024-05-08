#!/bin/bash
alias jq="$GITLAB_SCRIPTS_DIR/jq"

if [ -f $CI_PROJECT_DIR/.env ]
then
    source $CI_PROJECT_DIR/.env
fi

REACTION=$1
jq_script=".channel = \"$SLACK_CHANNEL\""
jq_script+="| .timestamp = \"$SLACK_TIMESTAMP\""
jq_script+="| .name = \"$REACTION\""

mkdir -p $TEMP_DIR
SLACK_PAYLOAD="$TEMP_DIR/reactionMessage.json"
SLACK_RESPONSE="$TEMP_DIR/reactionResponse.json"

jq "$jq_script" $GITLAB_TEMPLATES_DIR/slack/react.json > "$SLACK_PAYLOAD"

curl -s -H "Content-type: application/json; charset=utf-8" \
    -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
    -X POST \
    -d "@$SLACK_PAYLOAD" \
    -o "$SLACK_RESPONSE" \
    "https://slack.com/api/reactions.add"