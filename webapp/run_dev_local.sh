#!/usr/bin/env bash

# cd to script directory if not already there
SCRIPT_PATH=${0%/*}
if [ "$0" != "$SCRIPT_PATH" ] && [ "$SCRIPT_PATH" != "" ]; then 
  cd $SCRIPT_PATH
fi

PORT=8080
if [ "$1" == "--port" ]; then
  PORT=$2
fi

echo "Copying firebase constants into web folder"
cp ../deployment/coda_dev_constants.json web/assets/firebase_constants.json

webdev serve web:$PORT

echo "Cleaning up firebase constants file from web folder"
rm web/assets/firebase_constants.json
