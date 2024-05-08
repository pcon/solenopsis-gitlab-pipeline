#!/bin/bash
if [ "$SLACK_SKIP" == 'true' ]
then
    exit 0
fi

if [ $CI_JOB_STATUS == 'success' ]
then
    if [ $CI_JOB_STAGE == 'quality' ]
    then
        sh $GITLAB_SCRIPTS_DIR/slack/react.sh "sunny"
    elif [ $CI_JOB_STAGE == 'tests' ]
    then
        sh $GITLAB_SCRIPTS_DIR/slack/react.sh "mortar_board"
    elif [ $CI_JOB_STAGE == 'prod_deploy' ] || [ $CI_JOB_NAME == 'prod_deploy' ]
    then
        sh $GITLAB_SCRIPTS_DIR/slack/react.sh "tada"
    else
        sh $GITLAB_SCRIPTS_DIR/slack/react.sh "check"
    fi
elif [ $CI_JOB_STATUS == 'canceled' ]
then
    sh $GITLAB_SCRIPTS_DIR/slack/react.sh "no_entry_sign"
else
    sh $GITLAB_SCRIPTS_DIR/slack/react.sh "failed"

    if [ -f "$FAILURE_MESSAGE_FILE" ]
    then
        export FAILURE_MESSAGE="$(cat $FAILURE_MESSAGE_FILE)"
        sh $GITLAB_SCRIPTS_DIR/slack/threadMessage.sh "\`\`\`\n${FAILURE_MESSAGE}\n\`\`\`"
    fi
fi