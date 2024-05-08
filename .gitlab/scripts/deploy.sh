#!/bin/bash

solenopsis --tmpdir "$TEMP_DIR" -e instance \
    --maxpoll 9600 -l "$SRC_DIR" --antfile "$ANT_FILE" \
    --xsldir "$XSL_DIR" -i "$IGNORE_FILE" \
    delta-push 2>&1 | tee "$LOG_FILE"

FAILURE_MESSAGE=$(sed '/BUILD FAILED/,/BUILD FAILED/!d;//d' "$LOG_FILE")
if [ ! -z "$FAILURE_MESSAGE" ]
then
    echo "$FAILURE_MESSAGE" > $FAILURE_MESSAGE_FILE
    exit 1
fi

FAILURE_MESSAGE=$(sed '/DEPLOYMENT FAILED/,/DEPLOYMENT FAILED/!d;//d' "$LOG_FILE")
if [ ! -z "$FAILURE_MESSAGE" ]
then
    echo "$FAILURE_MESSAGE" > $FAILURE_MESSAGE_FILE
    exit 2
fi