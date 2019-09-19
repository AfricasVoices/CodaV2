import sys

import firebase_client_wrapper as fcw

if len(sys.argv) != 3:
    print("Usage python delete_unchecked_messages.py crypto_token dataset_id")
    print("Removes messages that don't currently have a label that is manually checked")
    exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
fcw.init_client(CRYPTO_TOKEN_PATH)

DATASET_ID = sys.argv[2]
fcw.delete_unchecked_messages(DATASET_ID)
print("Done")
