import firebase_client_wrapper as fcw

import json
import sys

if (len(sys.argv) < 2 or len(sys.argv) > 4):
    print ("Usage python get.py crypto_token [datasetid] [all, users, messages, schemes]")
    exit(1)

CONTENT_TYPE = "all"

CRYPTO_TOKEN_PATH = sys.argv[1]
fcw.init_client(CRYPTO_TOKEN_PATH)

if (len(sys.argv) == 2):
    print ("Datasets:")
    ids = fcw.get_dataset_ids()
    print (json.dumps(ids, indent=2))
    exit(0)

DATASET_ID = sys.argv[2]

if (len(sys.argv) == 4):
    CONTENT_TYPE = sys.argv[3]

if CONTENT_TYPE in ["all", "users"]:
    print ("Users:")
    print (json.dumps(fcw.get_user_ids(DATASET_ID), indent=2))

if CONTENT_TYPE in ["all", "schemes"]:
    print ("Schemes:")
    schemes_map = {}
    for scheme in fcw.get_code_scheme_ids(DATASET_ID):
        schemes_map[scheme] = fcw.get_code_scheme(DATASET_ID, scheme)
    print (json.dumps(schemes_map, indent=2))

if CONTENT_TYPE in ["all", "messages"]:
    print ("Messages:")
    messages_map = {}
    for message in fcw.get_all_messages(DATASET_ID):
        messages_map[message["MessageID"]] = message
    print (json.dumps(messages_map, indent=2))

