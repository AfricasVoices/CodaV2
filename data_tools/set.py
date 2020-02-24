import compute_coding_progress as cp
import firebase_client_wrapper as fcw

import json
import sys

import validate_code_scheme
import validate_message_structure
import validate_user_list

if (len(sys.argv) != 5):
    print ("Usage python set.py crypto_token dataset_id users|schemes|messages path")

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
    fcw.add_and_update_dataset_messages_content_batch(DATASET_ID, messages)
    print("Updated messages")

    print('Updating metrics for dataset: {}'.format(DATASET_ID))
    cp.compute_coding_progress(DATASET_ID, force_recount=True)
    print('Done')
