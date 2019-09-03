import firebase_client_wrapper as fcw

import json
import sys

import validate_code_scheme
import validate_message_structure
import validate_user_list

if (len(sys.argv) != 4):
    print ("Usage python duplicate.py crypto_token dataset_id scheme_id")
    print ("Adds another duplication of the scheme if provided")
    exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
fcw.init_client(CRYPTO_TOKEN_PATH)

DATASET_ID = sys.argv[2]
SCHEME_ID = sys.argv[3]

dataset_ids = fcw.get_dataset_ids()

if DATASET_ID not in dataset_ids: 
    print ("Dataset {} does not exist".format(DATASET_ID))
    exit (1)

scheme_ids = fcw.get_code_scheme_ids(DATASET_ID)
if SCHEME_ID not in scheme_ids:
    print ("Scheme {} does not exist".format(SCHEME_ID))
    exit (1)

exitsting_scheme_duplicates = [scheme for scheme in scheme_ids if scheme.startswith(SCHEME_ID)]

existing_scheme_count = len(exitsting_scheme_duplicates)
assert existing_scheme_count > 0

next_scheme_id = existing_scheme_count # Schemes are zero indexded
scheme = fcw.get_code_scheme(DATASET_ID, SCHEME_ID)
new_scheme_id = SCHEME_ID + "-{}".format(next_scheme_id)
scheme["SchemeID"] = new_scheme_id
fcw.set_code_scheme(DATASET_ID, scheme)

print ("Added: {}".format(new_scheme_id))

