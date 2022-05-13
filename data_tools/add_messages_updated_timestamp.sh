#!/bin/bash

set -e

# Check that the correct number of arguments were provided.
if [ $# -ne 3 ]; then
    echo "Usage: ./add_messages_updated_timestamp.sh <firestore-credentials-file-path> <dataset-ids-path> <data-dir>"
    exit
fi

# Assign the program arguments to bash variables.
FIRESTORE_CREDENTIALS_FILE_PATH=$1
DATASET_IDS_TXT_FILE_PATH=$2
DATA_DIR=$3

while IFS= read -r line
do
  echo "Downloading messages for dataset: $line to: $DATA_DIR"
  pipenv run python get.py "$FIRESTORE_CREDENTIALS_FILE_PATH" "$line" messages > "$DATA_DIR/$line.json"
done < "$DATASET_IDS_TXT_FILE_PATH"

for FILE_PATH in "$DATA_DIR/*.json";
do
  filename=`basename $FILE_PATH .json`
  echo "Uploading messages for dataset: $filename in $DATA_DIR"
  pipenv run python add.py "$FIRESTORE_CREDENTIALS_FILE_PATH" "$filename" messages "$FILE_PATH"
done
