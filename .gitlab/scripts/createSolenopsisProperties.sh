#!/bin/bash

echo "Creating Solenopsis properties file..."
cp .gitlab/config/solenopsis.properties "$HOME/solenopsis.properties"
sed -i "s@\$SOLENOPSIS_DIR@${SOLENOPSIS_DIR}@g" "$HOME/solenopsis.properties"
echo "Solenopsis properties file created."