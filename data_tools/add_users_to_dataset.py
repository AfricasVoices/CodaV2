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
parser.add_argument("--add", help="Add to existing users instead of replacing them", action='store_true')
parser.add_argument('ids', help='ids or paths', metavar='id', type=str, nargs='+')

args = parser.parse_args()
CRYPTO_TOKEN_PATH = args.crypto_token_path
DATASET_ID = args.dataset_id
MODE = args.use_paths
ADD = args.add
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

print ("Parsed new users for '{}': {}".format(DATASET_ID, users_to_add))

# Use a service account
# Setup Firebase
cred = credentials.Certificate(CRYPTO_TOKEN_PATH)
firebase_admin.initialize_app(cred)

db = firestore.client()

dataset_ref = db.collection(u'datasets').document(DATASET_ID)

dataset = dataset_ref.get()

if (not dataset.exists):
    print ("Dataset '{}' does not exist yet, can't add users".format(DATASET_ID))
    exit(-1)

if (ADD):
    existing_users = dataset.get('users')
    users_to_add.update(existing_users)
    print ("Appending new users to existing users")
else:
    print ("Replacing existing users")

users_to_add_unicode = []
for user_id in users_to_add:
    users_to_add_unicode.append(str(user_id))

print ("Setting users for '{}': {}".format(DATASET_ID, users_to_add_unicode))


dataset_ref.set({
    'users': users_to_add_unicode
})

print ("Done")
