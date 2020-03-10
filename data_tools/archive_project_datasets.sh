set -e

# Check that the correct number of arguments were provided.
if [ $# -ne 3 ]; then
    echo "Usage: ./archive_dataset.sh <crypto-token> <transfer-temp> <project-filter>"
    exit
fi

# Assign the program arguments to bash variables.
CRYPTO_TOKEN=$1
TRANFER_TEMP=$2
PROJECT_FILTER=$3

PROJECT_IDS=$(python get_dataset_ids.py "$1" | grep "$3")

for DATASET_ID in $PROJECT_IDS
do
    echo $DATASET_ID
    python backup.py "$1" "$DATASET_ID" > "$2/$DATASET_ID.json" 
    gzip -f "$2/$DATASET_ID.json"
done
