#!/bin/bash

# source has to be used here to make sure that the exported variables are available below
source $GITLAB_SCRIPTS_DIR/buildSecrets.sh

echo "Creating $CI_ENVIRONMENT_NAME properties file..."
cp ".gitlab/config/credentials/$CI_ENVIRONMENT_NAME.properties" "$SOLENOPSIS_DIR/credentials/instance.properties"
echo "" >> "$SOLENOPSIS_DIR/credentials/instance.properties" # This is because sometimes there's no newline at the end of the properties file
echo "username = $USERNAME" >> "$SOLENOPSIS_DIR/credentials/instance.properties"
echo "password = $PASSWORD" >> "$SOLENOPSIS_DIR/credentials/instance.properties"
echo "token = $TOKEN" >> "$SOLENOPSIS_DIR/credentials/instance.properties"
echo "$CI_ENVIRONMENT_NAME properties file created."