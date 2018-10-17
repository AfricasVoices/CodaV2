import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

import argparse
import json


parser = argparse.ArgumentParser(description="push users to firestore")
parser.add_argument("crypto_token_path", help="Path to crypto key")
parser.add_argument("dataset_id", help="ID of the dataset")
parser.add_argument("--use_paths", help="Use paths instead of reading items", action='store_const',
                    const="paths", default="emails")
parser.add_argument('ids', metavar='id', type=str, nargs='+',
                    help='ids or paths')

args = parser.parse_args()
CRYPTO_TOKEN_PATH = args.crypto_token_path
DATASET_ID = args.dataset_id
MODE = args.use_paths
IDS = args.ids

users_to_add = set()
if (MODE == "emails"):
    users_to_add.update(IDS)
elif (MODE == "paths"):
    for path in IDS:
        user_list = json.loads(open(path, 'r').read())
        users_to_add.update(user_list)

for user_id in users_to_add:
    assert (user_id.find("@") > 0)

print ("Adding users to '{}': {}".format(DATASET_ID, users_to_add))

# Use a service account
# Setup Firebase
cred = credentials.Certificate(CRYPTO_TOKEN_PATH)
firebase_admin.initialize_app(cred)

db = firestore.client()

col_ref = db.collection(u'datasets').document(DATASET_ID).collection("users")

for user_id in users_to_add:
  doc_ref = col_ref.document(user_id)
  doc_ref.set({
    'email': user_id
    }
)

print ("Done")