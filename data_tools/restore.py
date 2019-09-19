import argparse

import firebase_client_wrapper as fcw

import json
import sys


parser = argparse.ArgumentParser(description="Restores datasets from a backup file generated by backup.py")

parser.add_argument("--max-segment-size", type=int, required=False, default=sys.maxsize,
                    help="Maximum number of messages to upload to each segment before creating the next")
parser.add_argument("crypto_token_path", metavar="crypto-token-path",
                    help="Path to the Firestore credentials file")
parser.add_argument("backup_path", help="Path to a JSON file containing the data to restore")

args = parser.parse_args()

MAX_SEGMENT_SIZE = args.max_segment_size
CRYPTO_TOKEN_PATH = args.crypto_token_path
BACKUP_PATH = args.backup_path

fcw.init_client(CRYPTO_TOKEN_PATH)
project_id = json.load(open(CRYPTO_TOKEN_PATH, 'r'))["project_id"]

data = json.load(open(BACKUP_PATH, 'r'))

existing_ids = fcw.get_dataset_ids()

if len(existing_ids) > 0:
    print ("Target Firestore still has datasets, can't restore. Please delete all existing data first:")
    print ("Run:")
    print ("firebase -P {} firestore:delete -r datasets".format(project_id))
    print ("")
    exit (1)

for dataset_id in data.keys():
    print ("Starting to restore {}".format(dataset_id))
    fcw.set_user_ids(dataset_id, data[dataset_id]["users"])
    for scheme in data[dataset_id]["schemes"]:
        fcw.set_code_scheme(dataset_id, scheme)
    fcw.add_and_update_dataset_messages_content_batch(
        dataset_id, data[dataset_id]["messages"], max_segment_size=MAX_SEGMENT_SIZE)
    print ("Restore complete: {}".format(dataset_id))

