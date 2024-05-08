#!/bin/bash

if [ $SLACK_SKIP == 'true' ]
then
    exit 0
fi

if [ ! -z "$THREAD_MESSAGE" ]
then
    sh $GITLAB_SCRIPTS_DIR/slack/threadMessage.sh "$THREAD_MESSAGE"
fi