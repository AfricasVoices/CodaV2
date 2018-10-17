import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

import argparse

parser = argparse.ArgumentParser(description="push data to firestore")
parser.add_argument("crypto_token_path", help="Path to crypto key", nargs=1)

args = parser.parse_args()
CRYPTO_TOKEN_PATH = args.crypto_token_path[0]

# Use a service account
# Setup Firebase
cred = credentials.Certificate(CRYPTO_TOKEN_PATH)
firebase_admin.initialize_app(cred)

db = firestore.client()

datasets = db.collection(u'datasets').get()

print ("Existing dataset ids:")
for dataset in datasets:
    print(u'\t{}'.format(dataset.id))
