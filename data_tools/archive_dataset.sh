set -e

# Check that the correct number of arguments were provided.
if [ $# -ne 3 ]; then
    echo "Usage: ./archive_dataset.sh <crypto-token> <transfer-temp> <dataset>"
    exit
fi

# Assign the program arguments to bash variables.
CRYPTO_TOKEN=$1
TRANFER_TEMP=$2
DATASET=$3

python backup.py "$1" "$3" > "$2/$3.json" 
gzip "$2/$3.json"
