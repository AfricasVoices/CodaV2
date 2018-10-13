import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

import validate_code_scheme

import argparse
import json

parser = argparse.ArgumentParser(description="push data to firestore")
parser.add_argument("crypto_token_path", help="Path to crypto key", nargs=1)
parser.add_argument("dataset_id", help="ID of the dataset", nargs=1)
parser.add_argument("path_to_scheme", help="Path to JSON file defining the scheme", nargs=1)

args = parser.parse_args()
CRYPTO_TOKEN_PATH = args.crypto_token_path[0]
DATASET_ID = args.dataset_id[0]
CODING_SCHEME_PATH = args.path_to_scheme[0]

# Use a service account
# Setup Firebase
cred = credentials.Certificate(CRYPTO_TOKEN_PATH)
firebase_admin.initialize_app(cred)

db = firestore.client()
print ("client created")

# Validate coding scheme
coding_scheme = validate_code_scheme.verify_JSON_path(CODING_SCHEME_PATH)
print ("coding scheme validated: {}".format(CODING_SCHEME_PATH))

schemeId = coding_scheme["SchemeID"]

col_ref = db.collection(u'datasets').document(DATASET_ID).collection("code_schemes")
doc_ref = col_ref.document(schemeId)
doc_ref.set(coding_scheme)

print ("coding scheme updated: {} / {}".format(DATASET_ID, schemeId))
