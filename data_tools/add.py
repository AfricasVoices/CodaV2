import firebase_client_wrapper as fcw

import json
import sys

import validate_code_scheme
import validate_message_structure
import validate_user_list

# if (len(sys.argv) != 5):
#     print ("Usage python add.py crypto_token dataset_id users|schemes|messages path")
#     print ("add only adds data items that don't currently exist, by id. Existing data")
#     print ("items remain untouched")
#     exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
fcw.init_client(CRYPTO_TOKEN_PATH)

DATASET_ID = sys.argv[2]
CONTENT_TYPE = sys.argv[3]
PATH = sys.argv[4]

dataset_ids = fcw.get_dataset_ids()

if DATASET_ID not in dataset_ids:
    print ("WARNING: dataset {} does not exist, this will create a new dataset".format(DATASET_ID))


if CONTENT_TYPE not in ["users", "schemes", "messages"]:
    print ("update target {} not known".format(TARGET))
    exit(1)

if CONTENT_TYPE != "messages":
    print ("Only messages are currently supported")
    exit(1)

json_data = json.loads(open(PATH, 'r').read())
dataset_ref = fcw.get_dataset_ref(DATASET_ID)


if CONTENT_TYPE == "users":
    pass # Not implemented
elif CONTENT_TYPE == "schemes":
    pass # Not implemented
elif CONTENT_TYPE == "messages":
    added = 0
    skipped_existing = 0

    existing_ids = fcw.get_message_ids(DATASET_ID)
    print ("Existing Ids: {}".format(len(existing_ids)))

    for message in json_data:
        validate_message_structure.verify_message(message)
        id = message["MessageID"]
        if id in existing_ids:
            skipped_existing += 1
            continue

        message_ref = fcw.get_message_ref(DATASET_ID, id).set(message)
        print ("Written: {}".format(id))
        added += 1
    
    print ("Added: {}, Skipped: {}".format(added, skipped_existing))


