#!/bin/bash

if [ "$SLACK_SKIP" == 'true' ]
then
    exit 0
fi

if [ "$FIRST_JOB" == 'true' ]
then
    if [ "$CI_JOB_STAGE" == "tests" ]
    then
        FIRST_MESSAGE="Running all tests in $CI_ENVIRONMENT_NAME"
    else
        FIRST_MESSAGE="Starting deployment for $CI_ENVIRONMENT_NAME"
    fi

    sh $GITLAB_SCRIPTS_DIR/slack/firstMessage.sh "$FIRST_MESSAGE"
fi

if [ ! -z "$THREAD_MESSAGE" ] && [ "$CI_JOB_NAME" != "dev_tests" ]
then
    sh $GITLAB_SCRIPTS_DIR/slack/threadMessage.sh "$THREAD_MESSAGE"
fi