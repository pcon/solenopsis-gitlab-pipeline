#!/bin/bash
alias jq="$GITLAB_SCRIPTS_DIR/jq"

if [ -f $CI_PROJECT_DIR/.env ]
then
    source $CI_PROJECT_DIR/.env
fi

esc() {
    printf "%s" "$1" | sed -e 's/"/\\"/g'
}

JOB_MESSAGE=$1
SLACK_PAYLOAD="$TEMP_DIR/firstMessage.json"
SLACK_PAYLOAD_TEMP="${SLACK_PAYLOAD}.tmp"
SLACK_RESPONSE="$TEMP_DIR/firstResponse.json"
ISSUE_KEY=$(echo $CI_COMMIT_MESSAGE | grep -Eo "CPCCM-[0-9]+")

jq_script=".channel = \"$SLACK_CHANNEL\""
jq_script+="| .attachments[0].blocks[0].text.text = \"$(esc "$JOB_MESSAGE")\""
jq_script+="| .attachments[0].blocks[2].elements[0].url = \"$CI_JOB_URL\""

if [ -z "$CI_COMMIT_TAG_MESSAGE" ]
then
    jq_script+="| .attachments[0].blocks[1].elements[0].text = \"$(esc "$CI_COMMIT_MESSAGE")\""
else
    jq_script+="| .attachments[0].blocks[1].elements[0].text = \"$(esc "$CI_COMMIT_TAG_MESSAGE")\""
fi

jq "$jq_script" $GITLAB_TEMPLATES_DIR/slack/firstMessage.json > "$SLACK_PAYLOAD"

if [ -z "$CI_COMMIT_TAG" ]
then
    jq_script='del(.. | objects | select(.action_id == "view_tag"?))'
else
    TAG_URL="${CI_PROJECT_URL}/-/tags/${CI_COMMIT_TAG}"
    jq_script="(.. | objects | select(.action_id == \"view_tag\"?)).url = \"$TAG_URL\""
    jq_script+='| del(.. | objects | select(.action_id == "view_issue"))'
fi

mv "$SLACK_PAYLOAD" "$SLACK_PAYLOAD_TEMP"
jq "$jq_script" "$SLACK_PAYLOAD_TEMP" > "$SLACK_PAYLOAD"

if [ -z "$ISSUE_KEY" ]
then
    jq_script='del(.. | objects | select(.action_id == "view_issue"))'
else
    ISSUE_URL="https://issues.redhat.com/browse/${ISSUE_KEY}"
    jq_script="(.. | objects | select(.action_id == \"view_issue\"?)).url = \"$ISSUE_URL\""
fi

mv "$SLACK_PAYLOAD" "$SLACK_PAYLOAD_TEMP"
jq "$jq_script" "$SLACK_PAYLOAD_TEMP" > "$SLACK_PAYLOAD"

curl -s -H "Content-type: application/json; charset=utf-8" \
    -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
    -X POST \
    -d "@$SLACK_PAYLOAD" \
    -o "$SLACK_RESPONSE" \
    "https://slack.com/api/chat.postMessage"

export SLACK_TIMESTAMP=$(jq -r ".ts" $SLACK_RESPONSE)
echo "SLACK_TIMESTAMP=\"$SLACK_TIMESTAMP\"" >> .env