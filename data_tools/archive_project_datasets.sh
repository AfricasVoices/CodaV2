set -e

# Check that the correct number of arguments were provided.
if [ $# -ne 3 ]; then
    echo "Usage: ./archive_dataset.sh <crypto-token> <archive-folder> <project-filter>"
    exit
fi

# Assign the program arguments to bash variables.
CRYPTO_TOKEN=$1
ARCHIVE_FOLDER=$2
PROJECT_FILTER=$3

PROJECT_IDS=$(python get_dataset_ids.py "$CRYPTO_TOKEN" | grep "$PROJECT_FILTER")

for DATASET_ID in $PROJECT_IDS
do
    echo $DATASET_ID
    python backup.py "$CRYPTO_TOKEN" "$DATASET_ID" > "$ARCHIVE_FOLDER/$DATASET_ID.json" 
    gzip -f "$ARCHIVE_FOLDER/$DATASET_ID.json"
done
