import firebase_client_wrapper as fcw

import json
import sys

if (len(sys.argv) != 3):
    print ("Usage python delete_dataset.py crypto_token dataset_id")
    exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
DATASET_ID = sys.argv[2]

fcw.init_client(CRYPTO_TOKEN_PATH)

fcw.delete_dataset(DATASET_ID)
