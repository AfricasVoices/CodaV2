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
    CONTENT_TYPE = sys.argv[3].lower()

ALL = CONTENT_TYPE == "all"

if CONTENT_TYPE in ["all", "users"]:
    if ALL: 
        print ("Users:")
    print (json.dumps(fcw.get_user_ids(DATASET_ID), indent=2))

if CONTENT_TYPE in ["all", "schemes"]:
    if ALL:
        print ("Schemes:")
    schemes = []
    for scheme in fcw.get_code_scheme_ids(DATASET_ID):
        schemes.append(fcw.get_code_scheme(DATASET_ID, scheme))
    print (json.dumps(schemes, indent=2))

if CONTENT_TYPE in ["all", "messages"]:
    if ALL:
        print ("Messages:")
    messages = []
    for message in fcw.get_all_messages(DATASET_ID):
        messages.append(message)
    messages.sort(key=lambda msg: msg["SequenceNumber"])
    print (json.dumps(messages, indent=2))

