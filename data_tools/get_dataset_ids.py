import argparse

import firebase_client_wrapper as fcw

parser = argparse.ArgumentParser(description="push data to firestore")
parser.add_argument("crypto_token_path", help="Path to crypto key", nargs=1)

args = parser.parse_args()
CRYPTO_TOKEN_PATH = args.crypto_token_path[0]

# Use a service account
# Setup Firebase
fcw.init_client(CRYPTO_TOKEN_PATH)
existing_dataset_ids = fcw.get_dataset_ids()

print("Existing dataset ids:")
print("")
for dataset_id in existing_dataset_ids:
    print(u'{}'.format(dataset_id))
