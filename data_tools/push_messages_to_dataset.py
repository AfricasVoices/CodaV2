import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

import validate_message_structure

import argparse
import json

parser = argparse.ArgumentParser(description="push messages to firestore")
parser.add_argument("crypto_token_path", help="Path to crypto key", nargs=1)
parser.add_argument("dataset_id", help="ID of the dataset", nargs=1)
parser.add_argument("path_to_messages", help="Path to JSON file listing the messages", nargs=1)

args = parser.parse_args()
CRYPTO_TOKEN_PATH = args.crypto_token_path[0]
DATASET_ID = args.dataset_id[0]
MESSAGES_PATH = args.path_to_messages[0]

# Use a service account
# Setup Firebase
cred = credentials.Certificate(CRYPTO_TOKEN_PATH)
firebase_admin.initialize_app(cred)

db = firestore.client()
print ("client created")

# Validate message structure
messages = validate_message_structure.verify_JSON_path(MESSAGES_PATH)
print ("message structure validated: {}".format(MESSAGES_PATH))

col_ref = db.collection(u'datasets').document(DATASET_ID).collection("messages")

for message in messages:
  messageId = message["MessageID"]
  doc_ref = col_ref.document(messageId)
  doc_ref.set(message)

print ("{} messages updated: {}".format(len(messages), DATASET_ID))
