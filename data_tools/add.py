import argparse
import json
import sys

import compute_coding_progress as cp
import firebase_client_wrapper as fcw
import validate_code_scheme
import validate_message_structure

parser = argparse.ArgumentParser(description="Adds data items that don't currently exist, by id. "
                                             "Existing data items remain untouched")

parser.add_argument("--max-segment-size", type=int, required=False, default=sys.maxsize,
                    help="Maximum number of messages to upload to each segment before creating the next")
parser.add_argument("crypto_token_path", metavar="crypto-token-path",
                    help="Path to the Firestore credentials file")
parser.add_argument("dataset_id", metavar="dataset-id", help="Id of dataset to add data to")
parser.add_argument("content_type", choices=["users", "schemes", "messages"], help="Type of data to add")
parser.add_argument("path", help="Path to a JSON file containing the data to add")

args = parser.parse_args()

MAX_SEGMENT_SIZE = args.max_segment_size
CRYPTO_TOKEN_PATH = args.crypto_token_path
DATASET_ID = args.dataset_id
CONTENT_TYPE = args.content_type
PATH = args.path

fcw.init_client(CRYPTO_TOKEN_PATH)

dataset_ids = fcw.get_dataset_ids()
if DATASET_ID not in dataset_ids:
    print("WARNING: dataset {} does not exist, this will create a new dataset".format(DATASET_ID))

if CONTENT_TYPE not in ["messages", "schemes"]:
    print("Only messages and schemes are currently supported")
    exit(1)

json_data = json.loads(open(PATH, 'r').read())

if CONTENT_TYPE == "users":
    pass # Not implemented
elif CONTENT_TYPE == "schemes":
    added = 0
    skipped_existing = 0

    existing_ids = fcw.get_code_scheme_ids(DATASET_ID)
    print ("Existing Ids: {}".format(len(existing_ids)))
    if json_data is list:
        schemes = json_data
    else:
        assert isinstance(json_data, dict)
        schemes = [ json_data ]
    
    for scheme in schemes:
        validate_code_scheme.verify_scheme(scheme)
        id = scheme["SchemeID"]
    
        if id in existing_ids:
            skipped_existing += 1
            continue

        fcw.set_code_scheme(DATASET_ID, scheme)
        print ("Written: {}".format(id))
        added += 1
    
    print ("Added: {}, Skipped: {}".format(added, skipped_existing))
elif CONTENT_TYPE == "messages":
    added = 0
    skipped_existing = 0
    all_messages = fcw.get_all_messages(DATASET_ID)

    existing_ids = []
    highest_seq_no = -1
    for message in all_messages:
        existing_ids.append(message["MessageID"])
        if "SequenceNumber" in message.keys():
            if message["SequenceNumber"] > highest_seq_no:
                highest_seq_no = message["SequenceNumber"]

    print ("Existing Ids: {}".format(len(existing_ids)))
    print ("Highest seen sequence number: {}".format(highest_seq_no))

    next_seq_no = highest_seq_no + 1

    messages_to_write = []

    for message in json_data:
        validate_message_structure.verify_message(message)
        id = message["MessageID"]
        if id in existing_ids:
            skipped_existing += 1
            continue

        if "SequenceNumber" not in message.keys():
            message["SequenceNumber"] = next_seq_no
            next_seq_no += 1
        
        messages_to_write.append(message)
        added += 1
    
    print ("About to batch add: {}".format(added, skipped_existing))
    fcw.add_and_update_dataset_messages_content_batch(DATASET_ID, messages_to_write, max_segment_size=MAX_SEGMENT_SIZE)
    print ("Batch add complete: {}, Skipped: {}".format(added, skipped_existing))
    
    print('Updating metrics for dataset: {}'.format(DATASET_ID))
    cp.compute_coding_progress(DATASET_ID, force_recount=True)
    print('Done')
