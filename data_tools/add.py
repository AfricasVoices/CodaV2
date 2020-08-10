import json
import sys

import firebase_client_wrapper as fcw
import validate_code_scheme
import validate_message_structure

if (len(sys.argv) != 5):
    print ("Usage python add.py crypto_token dataset_id users|schemes|messages path")
    print ("add only adds data items that don't currently exist, by id. Existing data")
    print ("items remain untouched")
    exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
fcw.init_client(CRYPTO_TOKEN_PATH)

DATASET_ID = sys.argv[2]
CONTENT_TYPE = sys.argv[3]
PATH = sys.argv[4]

dataset_ids = fcw.get_dataset_ids()

if DATASET_ID not in dataset_ids:
    print ("WARNING: dataset {} does not exist, this will create a new dataset".format(DATASET_ID))


if CONTENT_TYPE not in ["users", "schemes", "messages"]:
    print ("update content type {} not known".format(CONTENT_TYPE))
    exit(1)

if CONTENT_TYPE not in  ["messages", "schemes"]:
    print ("Only messages and schemes are currently supported")
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

    existing_ids = set()
    for message in all_messages:
        existing_ids.add(message["MessageID"])

    messages_to_write = []
    for message in json_data:
        validate_message_structure.verify_message(message)
        id = message["MessageID"]
        if id in existing_ids:
            skipped_existing += 1
            continue

        messages_to_write.append(message)
        added += 1
    
    print ("To add: {}, Skipping: {}".format(added, skipped_existing))

    fcw.add_messages_content_batch(DATASET_ID, messages_to_write)
