import argparse

import firebase_client_wrapper as fcw

import json
import sys

import validate_code_scheme
import validate_message_structure
import validate_user_list

# TODO: Given that this script sometimes sets and sometimes adds and updates (depending on what content_type is)
#       'set.py' is probably not the best name.
parser = argparse.ArgumentParser(description="If content_type is 'schemes' or 'messages', then adds new "
                                             "messages/schemes and updates existing messages by id. "
                                             "If content_type is 'users', sets the users to the list provided")

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
    print ("WARNING: dataset {} does not exist, this will create a new dataset".format(DATASET_ID))


if CONTENT_TYPE not in ["users", "schemes", "messages"]:
    print ("update content_type {} not known".format(CONTENT_TYPE))
    exit(1)


json_data = json.loads(open(PATH, 'r').read())

if CONTENT_TYPE == "users":
    validate_user_list.verify_JSON_path(PATH)
    users_list = json_data
    print ("Setting users for '{}': {}".format(DATASET_ID, users_list))
    fcw.set_user_ids(DATASET_ID, users_list)
    print ("Done")
elif CONTENT_TYPE == "schemes":
    for scheme in json_data:
        validate_code_scheme.verify_scheme(scheme)
        id = scheme["SchemeID"]
        fcw.set_code_scheme(DATASET_ID, scheme)
        
        print ("Updated: {}".format(id))
elif CONTENT_TYPE == "messages":
    for message in json_data:
        validate_message_structure.verify_message(message)
    
    messages = json_data
    fcw.add_and_update_dataset_messages_content_batch(DATASET_ID, messages, max_segment_size=MAX_SEGMENT_SIZE)
    print ("Updated messages")
