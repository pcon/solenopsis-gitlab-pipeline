#!/bin/bash

cd "$SCRIPTS_DIR/testclasses/"
npm install --cache "$NPM_CACHE"
node testclasses.js --srcpath "$SRC_DIR" | tee "$QA_LOG"
grep -qi FAILED "$QA_LOG"

if [ $? -eq 0 ]
then
    exit 1
fi

export PMD_CACHE="$PMD_CACHE_FILE"
cd "$SCRIPTS_DIR"
sh pmd.sh